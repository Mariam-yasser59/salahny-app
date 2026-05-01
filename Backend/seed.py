"""
Seed the database with test data.
Run from the Backend/ directory: python seed.py
"""
import asyncio
from datetime import datetime

from motor.motor_asyncio import AsyncIOMotorClient
from passlib.context import CryptContext

MONGODB_URL = "mongodb://localhost:27017"
DB_NAME = "salahny"
pwd_ctx = CryptContext(schemes=["bcrypt"], deprecated="auto")


async def seed():
    client = AsyncIOMotorClient(MONGODB_URL)
    db = client[DB_NAME]

    print("Clearing existing data...")
    await db.users.delete_many({})
    await db.vehicles.delete_many({})
    await db.services.delete_many({})

    print("Seeding users...")
    driver_doc = {
        "name": "Ahmed Hassan",
        "email": "driver@salahny.com",
        "phone": "01012345678",
        "password_hash": pwd_ctx.hash("password123"),
        "role": "driver",
        "wallet_balance": 500.0,
        "rating": 4.5,
        "total_bookings": 5,
        "is_active": True,
        "is_verified": True,
        "created_at": datetime.utcnow(),
    }
    workshop_doc = {
        "name": "Mohamed Ali",
        "email": "workshop@salahny.com",
        "phone": "01098765432",
        "password_hash": pwd_ctx.hash("password123"),
        "role": "workshop",
        "workshop_name": "Al-Motahed Auto Workshop",
        "address": "15 El-Tahrir St, Cairo",
        "specialty": "Engine & Diagnostics",
        "rating": 4.8,
        "review_count": 47,
        "is_open": True,
        "is_active": True,
        "is_verified": True,
        "jobs_done": 234,
        "services": ["Oil Change", "OBD Diagnostics", "Brake Service", "AC Service"],
        "wallet_balance": 0.0,
        "created_at": datetime.utcnow(),
    }
    workshop2_doc = {
        "name": "Khaled Ibrahim",
        "email": "workshop2@salahny.com",
        "phone": "01155556666",
        "password_hash": pwd_ctx.hash("password123"),
        "role": "workshop",
        "workshop_name": "Speed Masters Garage",
        "address": "88 Nasr City, Cairo",
        "specialty": "Transmission & Electrical",
        "rating": 4.6,
        "review_count": 31,
        "is_open": True,
        "is_active": True,
        "is_verified": True,
        "jobs_done": 178,
        "services": ["Transmission Service", "Battery Check", "Electrical Repair"],
        "wallet_balance": 0.0,
        "created_at": datetime.utcnow(),
    }

    r_driver = await db.users.insert_one(driver_doc)
    r_workshop = await db.users.insert_one(workshop_doc)
    r_workshop2 = await db.users.insert_one(workshop2_doc)

    print(f"  Driver ID    : {r_driver.inserted_id}")
    print(f"  Workshop 1 ID: {r_workshop.inserted_id}")
    print(f"  Workshop 2 ID: {r_workshop2.inserted_id}")

    print("Seeding vehicles...")
    await db.vehicles.insert_many([
        {
            "owner_id": str(r_driver.inserted_id),
            "make": "Toyota", "model": "Camry", "year": 2020,
            "plate": "ABC-1234", "color": "White", "fuel_type": "Gasoline",
            "mileage": 45000, "health": 85, "created_at": datetime.utcnow(),
        },
        {
            "owner_id": str(r_driver.inserted_id),
            "make": "Hyundai", "model": "Elantra", "year": 2018,
            "plate": "XYZ-9876", "color": "Silver", "fuel_type": "Gasoline",
            "mileage": 72000, "health": 72, "created_at": datetime.utcnow(),
        },
    ])

    print("Seeding services catalog...")
    await db.services.insert_many([
        {"name": "Oil Change", "category": "Maintenance", "description": "Full synthetic oil change with filter", "emoji": "🛢️", "price": 150, "duration_mins": 45, "is_popular": True},
        {"name": "OBD Diagnostics", "category": "Diagnostics", "description": "Full vehicle OBD-II scan with AI analysis", "emoji": "🔍", "price": 200, "duration_mins": 60, "is_popular": True},
        {"name": "Brake Service", "category": "Safety", "description": "Brake pads & rotor inspection", "emoji": "🔧", "price": 350, "duration_mins": 90, "is_popular": False},
        {"name": "AC Service", "category": "Comfort", "description": "AC recharge and leak check", "emoji": "❄️", "price": 250, "duration_mins": 60, "is_popular": False},
        {"name": "Battery Check", "category": "Electrical", "description": "Battery load test and terminal clean", "emoji": "🔋", "price": 100, "duration_mins": 30, "is_popular": True},
        {"name": "Tire Rotation", "category": "Maintenance", "description": "Rotate and balance all 4 tires", "emoji": "🔄", "price": 120, "duration_mins": 45, "is_popular": False},
        {"name": "Engine Tune-Up", "category": "Maintenance", "description": "Spark plugs, air filter, fuel system cleaning", "emoji": "⚙️", "price": 450, "duration_mins": 120, "is_popular": False},
        {"name": "Transmission Service", "category": "Drivetrain", "description": "Transmission fluid flush and filter", "emoji": "🚗", "price": 500, "duration_mins": 120, "is_popular": False},
    ])

    print("\nDone! Test accounts:")
    print("  Driver:     driver@salahny.com    / password123")
    print("  Workshop 1: workshop@salahny.com  / password123")
    print("  Workshop 2: workshop2@salahny.com / password123")
    client.close()


if __name__ == "__main__":
    asyncio.run(seed())
