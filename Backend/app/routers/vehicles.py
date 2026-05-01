from datetime import datetime
from typing import Optional

from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from ..database import get_db, to_str_id, to_str_ids
from ..dependencies import get_current_user

router = APIRouter(prefix="/vehicles", tags=["vehicles"])


class VehicleCreate(BaseModel):
    make: str
    model: str
    year: int
    plate: str
    color: str = "White"
    fuel_type: str = "Gasoline"
    mileage: float = 0


class VehicleUpdate(BaseModel):
    make: Optional[str] = None
    model: Optional[str] = None
    year: Optional[int] = None
    plate: Optional[str] = None
    color: Optional[str] = None
    fuel_type: Optional[str] = None
    mileage: Optional[float] = None


@router.get("/")
async def list_vehicles(user=Depends(get_current_user), db=Depends(get_db)):
    cursor = db.vehicles.find({"owner_id": str(user["_id"])})
    docs = await cursor.to_list(length=100)
    return to_str_ids(docs)


@router.post("/", status_code=201)
async def add_vehicle(body: VehicleCreate, user=Depends(get_current_user), db=Depends(get_db)):
    doc = {
        **body.model_dump(),
        "owner_id": str(user["_id"]),
        "health": 100,
        "created_at": datetime.utcnow(),
    }
    result = await db.vehicles.insert_one(doc)
    doc["id"] = str(result.inserted_id)
    doc.pop("_id", None)
    return doc


@router.get("/{vehicle_id}")
async def get_vehicle(vehicle_id: str, user=Depends(get_current_user), db=Depends(get_db)):
    try:
        oid = ObjectId(vehicle_id)
    except Exception:
        raise HTTPException(400, "Invalid vehicle ID")
    vehicle = await db.vehicles.find_one({"_id": oid, "owner_id": str(user["_id"])})
    if not vehicle:
        raise HTTPException(404, "Vehicle not found")
    return to_str_id(vehicle)


@router.put("/{vehicle_id}")
async def update_vehicle(vehicle_id: str, body: VehicleUpdate, user=Depends(get_current_user), db=Depends(get_db)):
    try:
        oid = ObjectId(vehicle_id)
    except Exception:
        raise HTTPException(400, "Invalid vehicle ID")
    vehicle = await db.vehicles.find_one({"_id": oid, "owner_id": str(user["_id"])})
    if not vehicle:
        raise HTTPException(404, "Vehicle not found")

    updates = {k: v for k, v in body.model_dump().items() if v is not None}
    if updates:
        await db.vehicles.update_one({"_id": oid}, {"$set": updates})
    updated = await db.vehicles.find_one({"_id": oid})
    return to_str_id(updated)


@router.delete("/{vehicle_id}", status_code=204)
async def delete_vehicle(vehicle_id: str, user=Depends(get_current_user), db=Depends(get_db)):
    try:
        oid = ObjectId(vehicle_id)
    except Exception:
        raise HTTPException(400, "Invalid vehicle ID")
    result = await db.vehicles.delete_one({"_id": oid, "owner_id": str(user["_id"])})
    if result.deleted_count == 0:
        raise HTTPException(404, "Vehicle not found")
