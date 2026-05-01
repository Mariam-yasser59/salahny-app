from datetime import datetime
from typing import Optional

from bson import ObjectId
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from ..database import get_db, to_str_id, to_str_ids
from ..dependencies import get_current_user
from ..services import ml_service

router = APIRouter(prefix="/diagnostics", tags=["diagnostics"])


class OBDScanRequest(BaseModel):
    vehicle_id: str
    sensor_readings: dict[str, float]
    fault_codes: list[str] = []


@router.post("/scan", status_code=201)
async def run_scan(body: OBDScanRequest, user=Depends(get_current_user), db=Depends(get_db)):
    try:
        v_oid = ObjectId(body.vehicle_id)
    except Exception:
        raise HTTPException(400, "Invalid vehicle ID")

    vehicle = await db.vehicles.find_one({"_id": v_oid})
    if not vehicle:
        raise HTTPException(404, "Vehicle not found")

    if not ml_service.is_loaded():
        raise HTTPException(503, "ML model is not available — please train and save the model first")

    prediction = ml_service.predict(body.sensor_readings)

    health_score = 100
    if prediction["risk_level"] == "critical":
        health_score = max(20, 100 - int(prediction["confidence"] * 80))
    elif prediction["risk_level"] == "warning":
        health_score = max(50, 100 - int(prediction["confidence"] * 40))

    await db.vehicles.update_one({"_id": v_oid}, {"$set": {"health": health_score}})

    doc = {
        "user_id": str(user["_id"]),
        "vehicle_id": body.vehicle_id,
        "vehicle_info": f"{vehicle['year']} {vehicle['make']} {vehicle['model']}",
        "date": datetime.utcnow().isoformat(),
        "sensor_readings": body.sensor_readings,
        "fault_codes": body.fault_codes,
        "predicted_failure": prediction["predicted_failure"],
        "confidence": prediction["confidence"],
        "risk_level": prediction["risk_level"],
        "is_healthy": prediction["is_healthy"],
        "health_score": health_score,
        "recommendations": prediction["recommendations"],
        "all_probabilities": prediction["all_probabilities"],
        "created_at": datetime.utcnow(),
    }
    result = await db.diagnostics.insert_one(doc)
    doc["id"] = str(result.inserted_id)
    doc.pop("_id", None)
    return doc


@router.get("/reports")
async def list_reports(
    vehicle_id: Optional[str] = None,
    user=Depends(get_current_user),
    db=Depends(get_db),
):
    query = {"user_id": str(user["_id"])}
    if vehicle_id:
        query["vehicle_id"] = vehicle_id

    cursor = db.diagnostics.find(query).sort("created_at", -1)
    docs = await cursor.to_list(length=50)
    return to_str_ids(docs)


@router.get("/{report_id}")
async def get_report(report_id: str, user=Depends(get_current_user), db=Depends(get_db)):
    try:
        oid = ObjectId(report_id)
    except Exception:
        raise HTTPException(400, "Invalid report ID")

    report = await db.diagnostics.find_one({"_id": oid})
    if not report:
        raise HTTPException(404, "Report not found")

    uid = str(user["_id"])
    if report["user_id"] != uid and user["role"] != "workshop":
        raise HTTPException(403, "Access denied")

    return to_str_id(report)
