from datetime import datetime, timedelta

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from ..database import get_db, to_str_id
from ..dependencies import get_current_user

router = APIRouter(tags=["packages"])

_PACKAGES = [
    {
        "id": "basic",
        "name": "Basic",
        "tagline": "For casual drivers",
        "duration_months": 1,
        "price": 49,
        "original_price": 69,
        "is_popular": False,
        "features": [
            "1 OBD Scan/month",
            "Basic fault detection",
            "Email diagnostic reports",
        ],
    },
    {
        "id": "pro",
        "name": "Pro",
        "tagline": "For regular maintenance",
        "duration_months": 3,
        "price": 129,
        "original_price": 189,
        "is_popular": True,
        "features": [
            "5 OBD Scans/month",
            "AI-powered fault prediction",
            "Priority workshop booking",
            "SMS & push alerts",
            "PDF diagnostic reports",
        ],
    },
    {
        "id": "fleet",
        "name": "Fleet",
        "tagline": "For fleet managers",
        "duration_months": 12,
        "price": 399,
        "original_price": 599,
        "is_popular": False,
        "features": [
            "Unlimited OBD scans",
            "Multi-vehicle management",
            "Fleet analytics dashboard",
            "Dedicated account manager",
            "API access",
        ],
    },
]


@router.get("/packages")
async def list_packages(_=Depends(get_current_user)):
    return _PACKAGES


@router.get("/packages/{package_id}")
async def get_package(package_id: str, _=Depends(get_current_user)):
    pkg = next((p for p in _PACKAGES if p["id"] == package_id), None)
    if not pkg:
        raise HTTPException(404, "Package not found")
    return pkg


class SubscribeRequest(BaseModel):
    package_id: str
    payment_method: str = "card"


@router.post("/subscriptions", status_code=201)
async def subscribe(body: SubscribeRequest, user=Depends(get_current_user), db=Depends(get_db)):
    pkg = next((p for p in _PACKAGES if p["id"] == body.package_id), None)
    if not pkg:
        raise HTTPException(404, "Package not found")

    expires_at = datetime.utcnow() + timedelta(days=30 * pkg["duration_months"])
    doc = {
        "user_id": str(user["_id"]),
        "package_id": body.package_id,
        "package_name": pkg["name"],
        "price": pkg["price"],
        "payment_method": body.payment_method,
        "status": "active",
        "expires_at": expires_at,
        "created_at": datetime.utcnow(),
    }
    result = await db.subscriptions.insert_one(doc)
    doc["id"] = str(result.inserted_id)
    doc.pop("_id", None)
    doc["expires_at"] = expires_at.isoformat()
    return doc


@router.get("/subscriptions/active")
async def get_active_subscription(user=Depends(get_current_user), db=Depends(get_db)):
    sub = await db.subscriptions.find_one(
        {
            "user_id": str(user["_id"]),
            "status": "active",
            "expires_at": {"$gt": datetime.utcnow()},
        },
        sort=[("created_at", -1)],
    )
    if not sub:
        return {"subscription": None}
    return to_str_id(sub)
