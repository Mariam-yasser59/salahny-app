from typing import Optional

from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from datetime import datetime

from ..database import get_db, to_str_id, to_str_ids
from ..dependencies import get_current_user, require_workshop

router = APIRouter(prefix="/services", tags=["services"])

_DEFAULT_SERVICES = [
    {"name": "Oil Change", "category": "Maintenance", "description": "Full synthetic oil change with filter replacement", "emoji": "🛢️", "price": 150, "duration_mins": 45, "is_popular": True},
    {"name": "OBD Diagnostics", "category": "Diagnostics", "description": "Full vehicle OBD-II diagnostic scan with AI analysis", "emoji": "🔍", "price": 200, "duration_mins": 60, "is_popular": True},
    {"name": "Brake Service", "category": "Safety", "description": "Brake pads & rotor inspection and replacement", "emoji": "🔧", "price": 350, "duration_mins": 90, "is_popular": False},
    {"name": "AC Service", "category": "Comfort", "description": "AC recharge, leak check, and filter replacement", "emoji": "❄️", "price": 250, "duration_mins": 60, "is_popular": False},
    {"name": "Battery Check", "category": "Electrical", "description": "Battery load test and terminal cleaning", "emoji": "🔋", "price": 100, "duration_mins": 30, "is_popular": True},
    {"name": "Tire Rotation", "category": "Maintenance", "description": "Rotate and balance all 4 tires", "emoji": "🔄", "price": 120, "duration_mins": 45, "is_popular": False},
    {"name": "Engine Tune-Up", "category": "Maintenance", "description": "Spark plugs, air filter, and fuel system cleaning", "emoji": "⚙️", "price": 450, "duration_mins": 120, "is_popular": False},
    {"name": "Transmission Service", "category": "Drivetrain", "description": "Transmission fluid flush and filter change", "emoji": "🚗", "price": 500, "duration_mins": 120, "is_popular": False},
]


@router.get("/")
async def list_services(category: Optional[str] = None, db=Depends(get_db), _=Depends(get_current_user)):
    query = {}
    if category:
        query["category"] = category
    cursor = db.services.find(query)
    docs = await cursor.to_list(length=100)
    if not docs:
        return _DEFAULT_SERVICES
    return to_str_ids(docs)


@router.get("/{service_id}")
async def get_service(service_id: str, db=Depends(get_db), _=Depends(get_current_user)):
    try:
        oid = ObjectId(service_id)
    except Exception:
        raise HTTPException(400, "Invalid service ID")
    service = await db.services.find_one({"_id": oid})
    if not service:
        raise HTTPException(404, "Service not found")
    return to_str_id(service)


class ServiceCreate(BaseModel):
    name: str
    category: str
    description: str
    emoji: str = "🔧"
    price: float
    duration_mins: int
    is_popular: bool = False


@router.post("/", status_code=201)
async def create_service(body: ServiceCreate, _=Depends(require_workshop), db=Depends(get_db)):
    doc = {**body.model_dump(), "created_at": datetime.utcnow()}
    result = await db.services.insert_one(doc)
    doc["id"] = str(result.inserted_id)
    doc.pop("_id", None)
    return doc
