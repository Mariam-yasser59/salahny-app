from motor.motor_asyncio import AsyncIOMotorClient, AsyncIOMotorDatabase
from typing import Optional

from .config import settings

_client: Optional[AsyncIOMotorClient] = None
_db: Optional[AsyncIOMotorDatabase] = None


async def connect_db():
    global _client, _db
    _client = AsyncIOMotorClient(settings.MONGODB_URL)
    _db = _client[settings.DATABASE_NAME]
    await _create_indexes()
    print(f"[DB] Connected to MongoDB → {settings.DATABASE_NAME}")


async def _create_indexes():
    await _db.users.create_index("email", unique=True)
    await _db.users.create_index("phone")
    await _db.vehicles.create_index("owner_id")
    await _db.bookings.create_index("driver_id")
    await _db.bookings.create_index("workshop_id")
    await _db.diagnostics.create_index("vehicle_id")
    await _db.diagnostics.create_index("user_id")
    await _db.messages.create_index([("room_id", 1), ("created_at", 1)])
    await _db.notifications.create_index("user_id")


async def close_db():
    global _client
    if _client:
        _client.close()


def get_db() -> AsyncIOMotorDatabase:
    return _db


def to_str_id(doc: dict) -> dict:
    if doc is None:
        return None
    doc = dict(doc)
    doc["id"] = str(doc.pop("_id"))
    return doc


def to_str_ids(docs: list) -> list:
    return [to_str_id(d) for d in docs]
