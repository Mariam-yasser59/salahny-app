import json
from datetime import datetime
from typing import Dict, List

from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException, Query, WebSocket, WebSocketDisconnect
from jose import JWTError, jwt
from pydantic import BaseModel

from ..config import settings
from ..database import get_db, to_str_id, to_str_ids
from ..dependencies import get_current_user

router = APIRouter(prefix="/chat", tags=["chat"])


class ConnectionManager:
    def __init__(self):
        self.active: Dict[str, List[WebSocket]] = {}

    async def connect(self, room_id: str, ws: WebSocket):
        await ws.accept()
        self.active.setdefault(room_id, []).append(ws)

    def disconnect(self, room_id: str, ws: WebSocket):
        if room_id in self.active:
            try:
                self.active[room_id].remove(ws)
            except ValueError:
                pass

    async def broadcast(self, room_id: str, message: dict):
        for ws in list(self.active.get(room_id, [])):
            try:
                await ws.send_json(message)
            except Exception:
                pass


manager = ConnectionManager()


def _room_id(a: str, b: str) -> str:
    return "_".join(sorted([a, b]))


class SendMessageRequest(BaseModel):
    recipient_id: str
    text: str


@router.get("/rooms")
async def list_rooms(user=Depends(get_current_user), db=Depends(get_db)):
    uid = str(user["_id"])
    cursor = db.chat_rooms.find({"participants": uid}).sort("last_message_at", -1).limit(50)
    docs = await cursor.to_list(50)
    return to_str_ids(docs)


@router.get("/{recipient_id}/messages")
async def get_messages(
    recipient_id: str,
    limit: int = Query(50, le=200),
    user=Depends(get_current_user),
    db=Depends(get_db),
):
    room_id = _room_id(str(user["_id"]), recipient_id)
    cursor = db.messages.find({"room_id": room_id}).sort("created_at", 1).limit(limit)
    docs = await cursor.to_list(length=limit)
    return to_str_ids(docs)


@router.post("/{recipient_id}/messages", status_code=201)
async def send_message(
    recipient_id: str,
    body: SendMessageRequest,
    user=Depends(get_current_user),
    db=Depends(get_db),
):
    uid = str(user["_id"])
    room_id = _room_id(uid, recipient_id)
    now = datetime.utcnow()

    msg = {
        "room_id": room_id,
        "sender_id": uid,
        "sender_name": user["name"],
        "recipient_id": recipient_id,
        "text": body.text,
        "is_read": False,
        "created_at": now,
    }
    result = await db.messages.insert_one(msg)

    serializable_msg = {**msg, "id": str(result.inserted_id), "created_at": now.isoformat()}
    serializable_msg.pop("_id", None)

    await db.chat_rooms.update_one(
        {"room_id": room_id},
        {
            "$set": {
                "room_id": room_id,
                "last_message": body.text,
                "last_message_at": now,
                "participants": [uid, recipient_id],
            }
        },
        upsert=True,
    )

    await manager.broadcast(room_id, serializable_msg)
    return serializable_msg


@router.put("/{recipient_id}/messages/read")
async def mark_messages_read(
    recipient_id: str,
    user=Depends(get_current_user),
    db=Depends(get_db),
):
    uid = str(user["_id"])
    room_id = _room_id(uid, recipient_id)
    await db.messages.update_many(
        {"room_id": room_id, "recipient_id": uid, "is_read": False},
        {"$set": {"is_read": True}},
    )
    return {"message": "Messages marked as read"}


@router.websocket("/ws/{room_id}")
async def websocket_endpoint(
    room_id: str,
    ws: WebSocket,
    token: str = Query(...),
):
    try:
        payload = jwt.decode(token, settings.JWT_SECRET, algorithms=[settings.JWT_ALGORITHM])
        user_id = payload.get("sub")
        if not user_id:
            await ws.close(code=1008)
            return
    except JWTError:
        await ws.close(code=1008)
        return

    db = get_db()
    await manager.connect(room_id, ws)
    try:
        while True:
            raw = await ws.receive_text()
            data = json.loads(raw)
            text = data.get("text", "").strip()
            if not text:
                continue

            now = datetime.utcnow()
            msg = {
                "room_id": room_id,
                "sender_id": user_id,
                "text": text,
                "is_read": False,
                "created_at": now,
            }
            result = await db.messages.insert_one(msg)
            broadcast_msg = {
                "id": str(result.inserted_id),
                "room_id": room_id,
                "sender_id": user_id,
                "text": text,
                "created_at": now.isoformat(),
            }
            await manager.broadcast(room_id, broadcast_msg)
    except WebSocketDisconnect:
        manager.disconnect(room_id, ws)
