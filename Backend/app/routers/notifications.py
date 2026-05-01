from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException

from ..database import get_db, to_str_id, to_str_ids
from ..dependencies import get_current_user

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.get("/")
async def list_notifications(user=Depends(get_current_user), db=Depends(get_db)):
    cursor = db.notifications.find({"user_id": str(user["_id"])}).sort("created_at", -1).limit(50)
    docs = await cursor.to_list(50)
    return to_str_ids(docs)


@router.get("/unread-count")
async def unread_count(user=Depends(get_current_user), db=Depends(get_db)):
    count = await db.notifications.count_documents({"user_id": str(user["_id"]), "is_read": False})
    return {"count": count}


@router.put("/read-all")
async def mark_all_read(user=Depends(get_current_user), db=Depends(get_db)):
    await db.notifications.update_many(
        {"user_id": str(user["_id"]), "is_read": False},
        {"$set": {"is_read": True}},
    )
    return {"message": "All notifications marked as read"}


@router.put("/{notification_id}/read")
async def mark_read(notification_id: str, user=Depends(get_current_user), db=Depends(get_db)):
    try:
        oid = ObjectId(notification_id)
    except Exception:
        raise HTTPException(400, "Invalid notification ID")

    result = await db.notifications.update_one(
        {"_id": oid, "user_id": str(user["_id"])},
        {"$set": {"is_read": True}},
    )
    if result.matched_count == 0:
        raise HTTPException(404, "Notification not found")
    return {"message": "Marked as read"}
