from datetime import datetime
from typing import Optional

from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel

from ..database import get_db, to_str_id, to_str_ids
from ..dependencies import get_current_user

router = APIRouter(prefix="/workshops", tags=["workshops"])


@router.get("/")
async def list_workshops(
    specialty: Optional[str] = None,
    is_open: Optional[bool] = None,
    limit: int = Query(20, le=100),
    db=Depends(get_db),
    _=Depends(get_current_user),
):
    query = {"role": "workshop"}
    if specialty:
        query["specialty"] = {"$regex": specialty, "$options": "i"}
    if is_open is not None:
        query["is_open"] = is_open

    cursor = db.users.find(query, {"password_hash": 0})
    docs = await cursor.to_list(length=limit)
    return to_str_ids(docs)


@router.get("/{workshop_id}")
async def get_workshop(workshop_id: str, db=Depends(get_db), _=Depends(get_current_user)):
    try:
        oid = ObjectId(workshop_id)
    except Exception:
        raise HTTPException(400, "Invalid workshop ID")
    workshop = await db.users.find_one({"_id": oid, "role": "workshop"}, {"password_hash": 0})
    if not workshop:
        raise HTTPException(404, "Workshop not found")
    return to_str_id(workshop)


@router.get("/{workshop_id}/reviews")
async def get_workshop_reviews(workshop_id: str, db=Depends(get_db), _=Depends(get_current_user)):
    cursor = db.reviews.find({"workshop_id": workshop_id}).sort("created_at", -1).limit(50)
    docs = await cursor.to_list(50)
    return to_str_ids(docs)


class ReviewCreate(BaseModel):
    rating: float
    comment: str


@router.post("/{workshop_id}/reviews", status_code=201)
async def add_review(
    workshop_id: str,
    body: ReviewCreate,
    user=Depends(get_current_user),
    db=Depends(get_db),
):
    if body.rating < 1 or body.rating > 5:
        raise HTTPException(400, "Rating must be between 1 and 5")

    try:
        oid = ObjectId(workshop_id)
    except Exception:
        raise HTTPException(400, "Invalid workshop ID")

    workshop = await db.users.find_one({"_id": oid, "role": "workshop"})
    if not workshop:
        raise HTTPException(404, "Workshop not found")

    doc = {
        "workshop_id": workshop_id,
        "user_id": str(user["_id"]),
        "user_name": user["name"],
        "rating": body.rating,
        "comment": body.comment,
        "created_at": datetime.utcnow(),
    }
    await db.reviews.insert_one(doc)

    # Recalculate average rating
    pipeline = [
        {"$match": {"workshop_id": workshop_id}},
        {"$group": {"_id": None, "avg": {"$avg": "$rating"}, "count": {"$sum": 1}}},
    ]
    agg = await db.reviews.aggregate(pipeline).to_list(1)
    if agg:
        await db.users.update_one(
            {"_id": oid},
            {"$set": {"rating": round(agg[0]["avg"], 1), "review_count": agg[0]["count"]}},
        )

    return {"message": "Review added"}


class WorkshopServicesUpdate(BaseModel):
    services: list[str]


@router.put("/services")
async def update_workshop_services(
    body: WorkshopServicesUpdate,
    user=Depends(get_current_user),
    db=Depends(get_db),
):
    if user["role"] != "workshop":
        raise HTTPException(403, "Workshop access only")
    await db.users.update_one({"_id": user["_id"]}, {"$set": {"services": body.services}})
    return {"message": "Services updated", "services": body.services}
