"""
Salahny ML Microservice - OBD-II Fault Prediction
Run: python app.py
Listens on: http://localhost:5001
"""
import os
from pathlib import Path

import joblib
import numpy as np
import pandas as pd
from flask import Flask, jsonify, request

app = Flask(__name__)

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

# Realistic median values based on training data profiles.
# Used as fallback when a feature is missing from the request.
FEATURE_MEDIANS = {
    "ENGINE_RUN_TIME": 600,
    "ENGINE_RPM": 1500,
    "VEHICLE_SPEED": 40,
    "THROTTLE": 20,
    "ENGINE_LOAD": 35,
    "COOLANT_TEMPERATURE": 90,
    "LONG_TERM_FUEL_TRIM_BANK_1": 0.0,
    "SHORT_TERM_FUEL_TRIM_BANK_1": 0.0,
    "INTAKE_MANIFOLD_PRESSURE": 60,
    "FUEL_TANK": 55,
    "ABSOLUTE_THROTTLE_B": 20,
    "PEDAL_D": 20,
    "PEDAL_E": 20,
    "COMMANDED_THROTTLE_ACTUATOR": 20,
    "FUEL_AIR_COMMANDED_EQUIV_RATIO": 1.0,
    "ABSOLUTE_BAROMETRIC_PRESSURE": 101,
    "RELATIVE_THROTTLE_POSITION": 15,
    "INTAKE_AIR_TEMP": 35,
    "TIMING_ADVANCE": 10,
    "CATALYST_TEMPERATURE_BANK1_SENSOR1": 520,
    "CATALYST_TEMPERATURE_BANK1_SENSOR2": 490,
    "CONTROL_MODULE_VOLTAGE": 14.0,
    "COMMANDED_EVAPORATIVE_PURGE": 50,
}

# Severity per predicted fault type — not based on confidence score.
FAULT_SEVERITY = {
    "Healthy": "healthy",
    "Engine Overheating": "critical",
    "Alternator Failure": "critical",
    "Throttle Body Fault": "warning",
    "Transmission Slip": "critical",
    "O2 Sensor Failure": "warning",
    "Thermostat Stuck Open": "warning",
    "Crankshaft Position Sensor Failure": "critical",
}

RECOMMENDATIONS = {
    "O2 Sensor Failure": ["Replace the oxygen sensor", "Check fuel mixture", "Inspect the exhaust system"],
    "Engine Overheating": ["Check coolant level", "Inspect the radiator", "Check the thermostat", "Stop driving if warning appears"],
    "Thermostat Stuck Open": ["Replace the thermostat", "Check coolant temperature sensor"],
    "Alternator Failure": ["Test battery voltage (should be 13.8-14.4V)", "Replace the alternator", "Check the drive belt"],
    "Transmission Slip": ["Check transmission fluid", "Inspect transmission bands", "Schedule transmission service"],
    "Crankshaft Position Sensor Failure": ["Replace crankshaft position sensor", "Check engine timing"],
    "Throttle Body Fault": ["Clean the throttle body", "Check throttle position sensor"],
    "Healthy": ["Vehicle is in good condition", "Continue regular maintenance schedule"],
}

SERVICE_ROOT = Path(__file__).resolve().parent
REPO_ROOT = SERVICE_ROOT.parents[1] if len(SERVICE_ROOT.parents) > 1 else SERVICE_ROOT
MODEL_PATH = Path(
    os.getenv(
        "MODEL_PATH",
        SERVICE_ROOT / "models" / "obd2_rf_model.pkl"
        if (SERVICE_ROOT / "models" / "obd2_rf_model.pkl").exists()
        else REPO_ROOT / "AI and ML" / "obd2_rf_model.pkl",
    )
)
ENCODER_PATH = Path(
    os.getenv(
        "ENCODER_PATH",
        SERVICE_ROOT / "models" / "obd2_label_encoder.pkl"
        if (SERVICE_ROOT / "models" / "obd2_label_encoder.pkl").exists()
        else REPO_ROOT / "AI and ML" / "obd2_label_encoder.pkl",
    )
)

model, encoder = None, None

try:
    model = joblib.load(MODEL_PATH)
    encoder = joblib.load(ENCODER_PATH)
    print(f"[ML] Model loaded from {MODEL_PATH.resolve()}")
except Exception as e:
    print(f"[ML] Could not load model: {e}")
    print("[ML] Run the ML training script first to generate .pkl files")


def get_recommendations(failure: str) -> list:
    for key, recs in RECOMMENDATIONS.items():
        if key.lower() in failure.lower() or failure.lower() in key.lower():
            return recs
    return ["Schedule a workshop visit", "Run a full diagnostic scan"]


def _num(raw: dict, *keys: str, default: float = 0) -> float:
    normalized = {str(k).upper().replace(" ", "_"): v for k, v in raw.items()}
    for key in keys:
        value = normalized.get(key.upper().replace(" ", "_"))
        if value is None:
            continue
        try:
            return float(value)
        except (TypeError, ValueError):
            return default
    return default


def rule_based_prediction(raw: dict) -> dict:
    coolant = _num(raw, "COOLANT_TEMPERATURE", "ENGINE_COOLANT_TEMPERATUREC")
    rpm = _num(raw, "ENGINE_RPM", "ENGINE_RPMRPM")
    speed = _num(raw, "VEHICLE_SPEED", "SPEED_KMH")
    voltage = _num(raw, "CONTROL_MODULE_VOLTAGE", "BATTERY", "VOLTAGE", default=12.6)
    st_fuel_trim = _num(raw, "SHORT_TERM_FUEL_TRIM_BANK_1")
    lt_fuel_trim = _num(raw, "LONG_TERM_FUEL_TRIM_BANK_1")
    lambda_ratio = _num(raw, "FUEL_AIR_COMMANDED_EQUIV_RATIO", default=1.0)
    throttle = _num(raw, "THROTTLE")
    engine_load = _num(raw, "ENGINE_LOAD")

    issues = []
    if coolant >= 105:
        issues.append("Engine Overheating")
    if coolant > 0 and coolant < 76 and rpm > 500:
        issues.append("Thermostat Stuck Open")
    if rpm >= 4500 and speed < 20:
        issues.append("Throttle Body Fault")
    if 0 < voltage < 12.1:
        issues.append("Alternator Failure")
    if rpm >= 3500 and engine_load >= 50 and speed < 45:
        issues.append("Transmission Slip")
    if st_fuel_trim >= 18 or lt_fuel_trim >= 10 or lambda_ratio < 0.94:
        issues.append("O2 Sensor Failure")

    if issues:
        predicted = issues[0]  # Most specific match wins
        risk_level = FAULT_SEVERITY.get(predicted, "warning")
        confidence = 0.72 if risk_level == "critical" else 0.60
    else:
        predicted = "Healthy"
        risk_level = "healthy"
        confidence = 0.5

    return {
        "success": True,
        "prediction": predicted,
        "probability": confidence,
        "severity": risk_level,
        "recommendation": " ".join(get_recommendations(predicted)),
        "modelVersion": "rule-based-fallback-v1",
        "predicted_failure": predicted,
        "confidence": confidence,
        "risk_level": risk_level,
        "is_healthy": risk_level == "healthy",
        "recommendations": get_recommendations(predicted),
        "all_probabilities": {predicted: confidence},
        "model_source": "rule_based_fallback",
    }


@app.route("/predict", methods=["POST"])
def predict():
    data = request.json or {}
    raw = data.get("sensor_readings", data)

    if model is None or encoder is None:
        return jsonify(rule_based_prediction(raw))

    normalized = {k.upper().replace(" ", "_"): v for k, v in raw.items()}
    row = {f: normalized.get(f, FEATURE_MEDIANS.get(f, 0)) for f in FEATURES}
    x = pd.DataFrame([row])

    proba = model.predict_proba(x)[0]
    pred_idx = int(np.argmax(proba))
    predicted = encoder.inverse_transform([pred_idx])[0]
    confidence = float(proba[pred_idx])

    is_healthy = predicted.lower() in ("healthy", "none", "normal")
    risk_level = FAULT_SEVERITY.get(predicted, "healthy" if is_healthy else "warning")

    return jsonify({
        "success": True,
        "prediction": predicted,
        "probability": confidence,
        "severity": risk_level,
        "recommendation": " ".join(get_recommendations(predicted)),
        "modelVersion": "obd2-rf-v1",
        "predicted_failure": predicted,
        "confidence": confidence,
        "risk_level": risk_level,
        "is_healthy": is_healthy,
        "recommendations": get_recommendations(predicted),
        "all_probabilities": {cls: float(p) for cls, p in zip(encoder.classes_, proba)},
        "model_source": "random_forest",
    })


@app.route("/health", methods=["GET"])
def health():
    return jsonify(
        {
            "success": True,
            "status": "ok",
            "service": "salahny-ml-service",
            "model_loaded": model is not None,
            "encoder_loaded": encoder is not None,
            "model_path": str(MODEL_PATH),
        }
    )


if __name__ == "__main__":
    port = int(os.getenv("PORT", 5001))
    app.run(host="0.0.0.0", port=port, debug=False)
