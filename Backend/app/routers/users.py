from datetime import datetime
from typing import Optional

from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException
from passlib.context import CryptContext
from pydantic import BaseModel, EmailStr

from ..database import get_db, to_str_id
from ..dependencies import get_current_user

router = APIRouter(prefix="/users", tags=["users"])
pwd_ctx = CryptContext(schemes=["bcrypt"], deprecated="auto")


class UpdateProfileRequest(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[EmailStr] = None
    workshop_name: Optional[str] = None
    address: Optional[str] = None
    specialty: Optional[str] = None
    is_open: Optional[bool] = None


class ChangePasswordRequest(BaseModel):
    current_password: str
    new_password: str


def _safe_user(user: dict) -> dict:
    user.pop("password_hash", None)
    return user


@router.get("/profile")
async def get_profile(user=Depends(get_current_user)):
    return to_str_id(_safe_user(dict(user)))


@router.put("/profile")
async def update_profile(body: UpdateProfileRequest, user=Depends(get_current_user), db=Depends(get_db)):
    updates = {k: v for k, v in body.model_dump().items() if v is not None}
    if not updates:
        raise HTTPException(400, "No fields to update")
    updates["updated_at"] = datetime.utcnow()
    await db.users.update_one({"_id": user["_id"]}, {"$set": updates})
    updated = await db.users.find_one({"_id": user["_id"]})
    return to_str_id(_safe_user(updated))


@router.put("/password")
async def change_password(body: ChangePasswordRequest, user=Depends(get_current_user), db=Depends(get_db)):
    if not pwd_ctx.verify(body.current_password, user["password_hash"]):
        raise HTTPException(400, "Current password is incorrect")
    await db.users.update_one(
        {"_id": user["_id"]},
        {"$set": {"password_hash": pwd_ctx.hash(body.new_password)}},
    )
    return {"message": "Password updated successfully"}


@router.get("/{user_id}")
async def get_user(user_id: str, db=Depends(get_db), _=Depends(get_current_user)):
    try:
        oid = ObjectId(user_id)
    except Exception:
        raise HTTPException(400, "Invalid user ID")
    user = await db.users.find_one({"_id": oid})
    if not user:
        raise HTTPException(404, "User not found")
    return to_str_id(_safe_user(user))
