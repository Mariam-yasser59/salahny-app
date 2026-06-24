from datetime import datetime
import os
import re

from flask import Flask, jsonify, request

app = Flask(__name__)


@app.get("/health")
def health():
    return jsonify(
        {
            "success": True,
            "message": "CV verification service is running",
            "service": "salahny-cv-service",
        }
    )


def _decode_text(file_bytes):
    try:
        return file_bytes.decode("utf-8", errors="ignore").lower()
    except Exception:
        return ""


def _extract_fields(text, role):
    fields = {}
    license_match = re.search(r"(?:license|registration|permit)\s*(?:no|number)?[:\s#-]*([a-z0-9-]{4,})", text)
    expiry_match = re.search(r"(?:exp|expiry|expires)\s*[:\s-]*(\d{4}-\d{2}-\d{2})", text)
    name_match = re.search(r"(?:name|business)\s*[:\s-]*([a-z][a-z\s]{2,})", text)
    if license_match:
        fields["licenseNumber"] = license_match.group(1).strip()
    if expiry_match:
        fields["expiryDate"] = expiry_match.group(1)
    if name_match:
        fields["businessName" if role == "workshop" else "fullName"] = name_match.group(1).strip().title()
    return fields


@app.post("/verify-document")
def verify_document():
    uploaded = request.files.get("file")
    role = request.form.get("role", "")
    document_type = request.form.get("documentType", "")
    if uploaded is None or role not in {"driver", "workshop"}:
        return jsonify({"success": False, "message": "file and valid role are required"}), 400

    raw = uploaded.read()
    text = _decode_text(raw)
    lower_name = uploaded.filename.lower()
    issues = []
    role_keywords = (
        ["driver", "license"]
        if role == "driver"
        else ["permit", "registration", "business", "commercial", "workshop"]
    )
    keyword_hits = sum(1 for item in role_keywords if item in text or item in lower_name)
    fields = _extract_fields(text, role)

    if len(raw) < 24:
        issues.append("Document file is too small or empty")
    if keyword_hits == 0:
        issues.append("Expected document keywords were not detected")
    if not fields.get("licenseNumber"):
        issues.append("License or registration number not detected")

    confidence = min(0.95, 0.35 + keyword_hits * 0.18 + len(fields) * 0.12)
    if len(raw) < 24 or ("fake" in text and "official" not in text):
        status = "ai_rejected"
        is_valid = False
        confidence = max(confidence, 0.82)
    elif confidence >= 0.8 and not issues:
        status = "ai_verified"
        is_valid = True
    else:
        status = "needs_admin_review"
        is_valid = False

    return jsonify(
        {
            "success": True,
            "documentType": document_type,
            "isValid": is_valid,
            "confidence": round(confidence, 2),
            "extractedFields": fields,
            "issues": issues,
            "status": status,
            "checkedAt": datetime.utcnow().isoformat() + "Z",
        }
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "5002")))
