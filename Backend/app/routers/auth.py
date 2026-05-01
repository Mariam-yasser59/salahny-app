import random
import string
from datetime import datetime, timedelta

from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException
from jose import JWTError, jwt
from passlib.context import CryptContext
from pydantic import BaseModel, EmailStr

from ..config import settings
from ..database import get_db, to_str_id

router = APIRouter(prefix="/auth", tags=["auth"])
pwd_ctx = CryptContext(schemes=["bcrypt"], deprecated="auto")


class RegisterRequest(BaseModel):
    name: str
    email: EmailStr
    phone: str
    password: str
    role: str = "driver"
    # Workshop-only fields
    workshop_name: str | None = None
    address: str | None = None
    specialty: str | None = None


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class RefreshRequest(BaseModel):
    refresh_token: str


class OTPRequest(BaseModel):
    phone: str


class OTPVerifyRequest(BaseModel):
    phone: str
    otp: str


class ForgotPasswordRequest(BaseModel):
    email: EmailStr


class ResetPasswordRequest(BaseModel):
    token: str
    new_password: str


def _create_token(user_id: str, token_type: str) -> str:
    if token_type == "access":
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    else:
        expire = datetime.utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    payload = {"sub": user_id, "type": token_type, "exp": expire}
    return jwt.encode(payload, settings.JWT_SECRET, algorithm=settings.JWT_ALGORITHM)


@router.post("/register", status_code=201)
async def register(body: RegisterRequest, db=Depends(get_db)):
    if body.role not in ("driver", "workshop"):
        raise HTTPException(400, "Role must be 'driver' or 'workshop'")

    existing = await db.users.find_one({"email": body.email})
    if existing:
        raise HTTPException(400, "Email already registered")

    user_doc = {
        "name": body.name,
        "email": body.email,
        "phone": body.phone,
        "password_hash": pwd_ctx.hash(body.password),
        "role": body.role,
        "wallet_balance": 0.0,
        "rating": 0.0,
        "total_bookings": 0,
        "is_active": True,
        "is_verified": False,
        "created_at": datetime.utcnow(),
    }

    if body.role == "workshop":
        user_doc.update({
            "workshop_name": body.workshop_name or body.name,
            "address": body.address or "",
            "specialty": body.specialty or "General",
            "is_open": True,
            "jobs_done": 0,
            "review_count": 0,
            "services": [],
        })

    result = await db.users.insert_one(user_doc)
    user_id = str(result.inserted_id)

    return {
        "access_token": _create_token(user_id, "access"),
        "refresh_token": _create_token(user_id, "refresh"),
        "token_type": "bearer",
        "user": {"id": user_id, "name": body.name, "email": body.email, "role": body.role},
    }


@router.post("/login")
async def login(body: LoginRequest, db=Depends(get_db)):
    user = await db.users.find_one({"email": body.email})
    if not user or not pwd_ctx.verify(body.password, user["password_hash"]):
        raise HTTPException(401, "Invalid email or password")
    if not user.get("is_active", True):
        raise HTTPException(403, "Account deactivated")

    user_id = str(user["_id"])
    return {
        "access_token": _create_token(user_id, "access"),
        "refresh_token": _create_token(user_id, "refresh"),
        "token_type": "bearer",
        "user": {"id": user_id, "name": user["name"], "email": user["email"], "role": user["role"]},
    }


@router.post("/refresh")
async def refresh_token(body: RefreshRequest, db=Depends(get_db)):
    blacklisted = await db.token_blacklist.find_one({"token": body.refresh_token})
    if blacklisted:
        raise HTTPException(401, "Token has been revoked")

    try:
        payload = jwt.decode(body.refresh_token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])
        if payload.get("type") != "refresh":
            raise HTTPException(401, "Invalid token type")
        user_id = payload["sub"]
    except JWTError:
        raise HTTPException(401, "Invalid or expired refresh token")

    return {"access_token": _create_token(user_id, "access"), "token_type": "bearer"}


@router.post("/logout")
async def logout(body: RefreshRequest, db=Depends(get_db)):
    await db.token_blacklist.insert_one({"token": body.refresh_token, "created_at": datetime.utcnow()})
    return {"message": "Logged out successfully"}


@router.post("/otp/send")
async def send_otp(body: OTPRequest, db=Depends(get_db)):
    otp = "".join(random.choices(string.digits, k=6))
    await db.otps.replace_one(
        {"phone": body.phone},
        {"phone": body.phone, "otp": otp, "created_at": datetime.utcnow()},
        upsert=True,
    )
    print(f"[OTP] {body.phone} → {otp}")
    return {"message": "OTP sent", "dev_otp": otp}


@router.post("/otp/verify")
async def verify_otp(body: OTPVerifyRequest, db=Depends(get_db)):
    record = await db.otps.find_one({"phone": body.phone})
    if not record or record["otp"] != body.otp:
        raise HTTPException(400, "Invalid OTP")
    if (datetime.utcnow() - record["created_at"]).total_seconds() > 300:
        raise HTTPException(400, "OTP expired")

    await db.otps.delete_one({"phone": body.phone})
    await db.users.update_one({"phone": body.phone}, {"$set": {"is_verified": True}})
    return {"message": "Phone verified successfully"}


@router.post("/forgot-password")
async def forgot_password(body: ForgotPasswordRequest, db=Depends(get_db)):
    user = await db.users.find_one({"email": body.email})
    token = "".join(random.choices(string.ascii_letters + string.digits, k=32))
    if user:
        await db.password_resets.replace_one(
            {"email": body.email},
            {"email": body.email, "token": token, "created_at": datetime.utcnow()},
            upsert=True,
        )
        print(f"[RESET] {body.email} → token: {token}")
    return {"message": "If the email exists, a reset link has been sent", "dev_token": token}


@router.post("/reset-password")
async def reset_password(body: ResetPasswordRequest, db=Depends(get_db)):
    record = await db.password_resets.find_one({"token": body.token})
    if not record:
        raise HTTPException(400, "Invalid reset token")
    if (datetime.utcnow() - record["created_at"]).total_seconds() > 3600:
        raise HTTPException(400, "Reset token expired")

    new_hash = pwd_ctx.hash(body.new_password)
    await db.users.update_one({"email": record["email"]}, {"$set": {"password_hash": new_hash}})
    await db.password_resets.delete_one({"token": body.token})
    return {"message": "Password reset successfully"}
