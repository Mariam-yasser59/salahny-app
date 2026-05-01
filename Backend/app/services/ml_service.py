from pathlib import Path
from typing import Optional

import joblib
import numpy as np
import pandas as pd

FEATURES = [
    "ENGINE_RUN_TIME", "ENGINE_RPM", "VEHICLE_SPEED", "THROTTLE", "ENGINE_LOAD",
    "COOLANT_TEMPERATURE", "LONG_TERM_FUEL_TRIM_BANK_1", "SHORT_TERM_FUEL_TRIM_BANK_1",
    "INTAKE_MANIFOLD_PRESSURE", "FUEL_TANK", "ABSOLUTE_THROTTLE_B", "PEDAL_D", "PEDAL_E",
    "COMMANDED_THROTTLE_ACTUATOR", "FUEL_AIR_COMMANDED_EQUIV_RATIO",
    "ABSOLUTE_BAROMETRIC_PRESSURE", "RELATIVE_THROTTLE_POSITION", "INTAKE_AIR_TEMP",
    "TIMING_ADVANCE", "CATALYST_TEMPERATURE_BANK1_SENSOR1",
    "CATALYST_TEMPERATURE_BANK1_SENSOR2", "CONTROL_MODULE_VOLTAGE",
    "COMMANDED_EVAPORATIVE_PURGE",
]

_RECOMMENDATIONS = {
    "O2 Sensor Failure": [
        "Replace the oxygen sensor",
        "Check fuel mixture and combustion efficiency",
        "Inspect the exhaust system for leaks",
    ],
    "Engine Overheating": [
        "Check coolant level and top up if needed",
        "Inspect the radiator for blockages",
        "Check the thermostat is functioning",
        "Stop driving immediately if temperature warning appears",
    ],
    "Thermostat Stuck Open": [
        "Replace the thermostat",
        "Check coolant temperature sensor",
        "Inspect the cooling system for leaks",
    ],
    "Alternator Failure": [
        "Test battery voltage (should be 13.8–14.4V when running)",
        "Replace the alternator",
        "Check and replace the drive belt if worn",
    ],
    "Transmission Slip": [
        "Check transmission fluid level and condition",
        "Inspect transmission bands and clutch packs",
        "Schedule a full transmission service",
    ],
    "Crankshaft Position Sensor Failure": [
        "Replace the crankshaft position sensor",
        "Check engine timing and wiring harness",
    ],
    "Throttle Body Fault": [
        "Clean the throttle body",
        "Check the throttle position sensor",
        "Inspect the air intake for obstructions",
    ],
    "Healthy": [
        "Vehicle is in good condition",
        "Continue regular maintenance schedule",
        "Next service recommended in 5,000 km",
    ],
}

_model = None
_encoder = None


def load_model(model_path: str, encoder_path: str) -> bool:
    global _model, _encoder
    try:
        mp = Path(model_path)
        ep = Path(encoder_path)
        if not mp.exists():
            print(f"[ML] Model not found: {mp.resolve()}")
            return False
        if not ep.exists():
            print(f"[ML] Encoder not found: {ep.resolve()}")
            return False
        _model = joblib.load(mp)
        _encoder = joblib.load(ep)
        print(f"[ML] Model loaded successfully from {mp.resolve()}")
        return True
    except Exception as e:
        print(f"[ML] Failed to load model: {e}")
        return False


def is_loaded() -> bool:
    return _model is not None and _encoder is not None


def predict(sensor_readings: dict) -> dict:
    if not is_loaded():
        raise RuntimeError("ML model is not loaded")

    # Accept both uppercase and lowercase keys
    normalized = {k.upper().replace(" ", "_"): v for k, v in sensor_readings.items()}
    row = {f: normalized.get(f, 0) for f in FEATURES}
    X = pd.DataFrame([row])

    proba = _model.predict_proba(X)[0]
    pred_idx = int(np.argmax(proba))
    predicted = _encoder.inverse_transform([pred_idx])[0]
    confidence = float(proba[pred_idx])

    risk_level = _calc_risk(predicted, confidence)
    recommendations = _get_recommendations(predicted)

    return {
        "predicted_failure": predicted,
        "confidence": confidence,
        "risk_level": risk_level,
        "is_healthy": predicted.lower() in ("healthy", "none", "normal"),
        "recommendations": recommendations,
        "all_probabilities": {cls: float(p) for cls, p in zip(_encoder.classes_, proba)},
    }


def _calc_risk(failure: str, confidence: float) -> str:
    if failure.lower() in ("healthy", "none", "normal"):
        return "healthy"
    return "critical" if confidence > 0.7 else "warning"


def _get_recommendations(failure: str) -> list:
    for key, recs in _RECOMMENDATIONS.items():
        if key.lower() in failure.lower() or failure.lower() in key.lower():
            return recs
    return [
        "Schedule a workshop visit for a detailed inspection",
        "Run a full OBD-II diagnostic scan",
        "Avoid long trips until the issue is resolved",
    ]
