"""
Salahny ML Microservice — OBD-II Fault Prediction
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

RECOMMENDATIONS = {
    "O2 Sensor Failure":                  ["Replace the oxygen sensor", "Check fuel mixture", "Inspect the exhaust system"],
    "Engine Overheating":                 ["Check coolant level", "Inspect the radiator", "Check the thermostat", "Stop driving if warning appears"],
    "Thermostat Stuck Open":              ["Replace the thermostat", "Check coolant temperature sensor"],
    "Alternator Failure":                 ["Test battery voltage (should be 13.8–14.4V)", "Replace the alternator", "Check the drive belt"],
    "Transmission Slip":                  ["Check transmission fluid", "Inspect transmission bands", "Schedule transmission service"],
    "Crankshaft Position Sensor Failure": ["Replace crankshaft position sensor", "Check engine timing"],
    "Throttle Body Fault":                ["Clean the throttle body", "Check throttle position sensor"],
    "Healthy":                            ["Vehicle is in good condition", "Continue regular maintenance schedule"],
}

MODEL_PATH   = os.getenv("MODEL_PATH",   "../../AI and ML/obd2_rf_model.pkl")
ENCODER_PATH = os.getenv("ENCODER_PATH", "../../AI and ML/obd2_label_encoder.pkl")

model, encoder = None, None

try:
    model   = joblib.load(Path(MODEL_PATH))
    encoder = joblib.load(Path(ENCODER_PATH))
    print(f"[ML] Model loaded from {Path(MODEL_PATH).resolve()}")
except Exception as e:
    print(f"[ML] Could not load model: {e}")
    print("[ML] Run the AI Model training script first to generate .pkl files")


def get_recommendations(failure: str) -> list:
    for key, recs in RECOMMENDATIONS.items():
        if key.lower() in failure.lower() or failure.lower() in key.lower():
            return recs
    return ["Schedule a workshop visit", "Run a full diagnostic scan"]


@app.route("/predict", methods=["POST"])
def predict():
    if model is None or encoder is None:
        return jsonify({"error": "Model not loaded — run training script first"}), 503

    data = request.json or {}
    raw  = data.get("sensor_readings", {})

    # Normalize keys to uppercase
    normalized = {k.upper().replace(" ", "_"): v for k, v in raw.items()}
    row = {f: normalized.get(f, 0) for f in FEATURES}
    X   = pd.DataFrame([row])

    proba     = model.predict_proba(X)[0]
    pred_idx  = int(np.argmax(proba))
    predicted = encoder.inverse_transform([pred_idx])[0]
    confidence = float(proba[pred_idx])

    is_healthy = predicted.lower() in ("healthy", "none", "normal")
    risk_level = "healthy" if is_healthy else ("critical" if confidence > 0.7 else "warning")

    return jsonify({
        "predicted_failure":  predicted,
        "confidence":         confidence,
        "risk_level":         risk_level,
        "is_healthy":         is_healthy,
        "recommendations":    get_recommendations(predicted),
        "all_probabilities":  {cls: float(p) for cls, p in zip(encoder.classes_, proba)},
    })


@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "ok", "model_loaded": model is not None})


if __name__ == "__main__":
    port = int(os.getenv("PORT", 5001))
    app.run(host="0.0.0.0", port=port, debug=False)
