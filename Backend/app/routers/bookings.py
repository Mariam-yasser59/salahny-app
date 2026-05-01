from datetime import datetime
from typing import Optional

from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from ..database import get_db, to_str_id, to_str_ids
from ..dependencies import get_current_user

router = APIRouter(prefix="/bookings", tags=["bookings"])

VALID_STATUSES = [
    "pending", "accepted", "in_progress",
    "diagnostics_ready", "repair_in_progress", "completed", "cancelled",
]

_PROGRESS = {
    "pending": 0, "accepted": 20, "in_progress": 40,
    "diagnostics_ready": 60, "repair_in_progress": 80,
    "completed": 100, "cancelled": 0,
}


class BookingCreate(BaseModel):
    workshop_id: str
    vehicle_id: str
    service_name: str
    date: str
    time: str
    price: float = 0
    notes: Optional[str] = None


class StatusUpdate(BaseModel):
    status: str
    notes: Optional[str] = None


@router.get("/")
async def list_bookings(
    status: Optional[str] = None,
    user=Depends(get_current_user),
    db=Depends(get_db),
):
    if user["role"] == "driver":
        query = {"driver_id": str(user["_id"])}
    else:
        query = {"workshop_id": str(user["_id"])}

    if status:
        query["status"] = status

    cursor = db.bookings.find(query).sort("created_at", -1)
    docs = await cursor.to_list(length=100)
    return to_str_ids(docs)


@router.post("/", status_code=201)
async def create_booking(body: BookingCreate, user=Depends(get_current_user), db=Depends(get_db)):
    if user["role"] != "driver":
        raise HTTPException(403, "Only drivers can create bookings")

    try:
        workshop_oid = ObjectId(body.workshop_id)
        vehicle_oid = ObjectId(body.vehicle_id)
    except Exception:
        raise HTTPException(400, "Invalid ID format")

    workshop = await db.users.find_one({"_id": workshop_oid, "role": "workshop"})
    if not workshop:
        raise HTTPException(404, "Workshop not found")

    vehicle = await db.vehicles.find_one({"_id": vehicle_oid, "owner_id": str(user["_id"])})
    if not vehicle:
        raise HTTPException(404, "Vehicle not found or not yours")

    doc = {
        "driver_id": str(user["_id"]),
        "driver_name": user["name"],
        "driver_phone": user.get("phone", ""),
        "workshop_id": body.workshop_id,
        "workshop_name": workshop.get("workshop_name", workshop["name"]),
        "vehicle_id": body.vehicle_id,
        "vehicle_info": f"{vehicle['year']} {vehicle['make']} {vehicle['model']}",
        "service_name": body.service_name,
        "date": body.date,
        "time": body.time,
        "notes": body.notes,
        "price": body.price,
        "status": "pending",
        "progress": 0,
        "created_at": datetime.utcnow(),
    }
    result = await db.bookings.insert_one(doc)
    doc["id"] = str(result.inserted_id)
    doc.pop("_id", None)

    await db.notifications.insert_one({
        "user_id": body.workshop_id,
        "title": "New Booking Request",
        "body": f"{user['name']} booked {body.service_name} for {body.date} at {body.time}",
        "type": "booking",
        "is_read": False,
        "created_at": datetime.utcnow(),
    })

    return doc


@router.get("/{booking_id}")
async def get_booking(booking_id: str, user=Depends(get_current_user), db=Depends(get_db)):
    try:
        oid = ObjectId(booking_id)
    except Exception:
        raise HTTPException(400, "Invalid booking ID")

    booking = await db.bookings.find_one({"_id": oid})
    if not booking:
        raise HTTPException(404, "Booking not found")

    uid = str(user["_id"])
    if booking["driver_id"] != uid and booking["workshop_id"] != uid:
        raise HTTPException(403, "Access denied")

    return to_str_id(booking)


@router.put("/{booking_id}/status")
async def update_booking_status(
    booking_id: str,
    body: StatusUpdate,
    user=Depends(get_current_user),
    db=Depends(get_db),
):
    if body.status not in VALID_STATUSES:
        raise HTTPException(400, f"Invalid status. Must be one of: {VALID_STATUSES}")

    try:
        oid = ObjectId(booking_id)
    except Exception:
        raise HTTPException(400, "Invalid booking ID")

    booking = await db.bookings.find_one({"_id": oid})
    if not booking:
        raise HTTPException(404, "Booking not found")

    uid = str(user["_id"])
    if booking["workshop_id"] != uid and booking["driver_id"] != uid:
        raise HTTPException(403, "Access denied")

    updates = {
        "status": body.status,
        "progress": _PROGRESS.get(body.status, booking.get("progress", 0)),
        "updated_at": datetime.utcnow(),
    }
    if body.notes:
        updates["status_notes"] = body.notes

    await db.bookings.update_one({"_id": oid}, {"$set": updates})

    notify_id = booking["driver_id"] if user["role"] == "workshop" else booking["workshop_id"]
    await db.notifications.insert_one({
        "user_id": notify_id,
        "title": "Booking Update",
        "body": f"Your booking for {booking['service_name']} is now {body.status.replace('_', ' ')}",
        "type": "booking",
        "is_read": False,
        "created_at": datetime.utcnow(),
    })

    updated = await db.bookings.find_one({"_id": oid})
    return to_str_id(updated)


@router.get("/workshop/earnings")
async def get_earnings(user=Depends(get_current_user), db=Depends(get_db)):
    if user["role"] != "workshop":
        raise HTTPException(403, "Workshop access only")

    pipeline = [
        {"$match": {"workshop_id": str(user["_id"]), "status": "completed"}},
        {"$group": {"_id": None, "total": {"$sum": "$price"}, "count": {"$sum": 1}}},
    ]
    agg = await db.bookings.aggregate(pipeline).to_list(1)
    total = agg[0]["total"] if agg else 0
    count = agg[0]["count"] if agg else 0

    return {"total_earnings": total, "completed_jobs": count}
