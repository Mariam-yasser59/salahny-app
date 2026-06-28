from datetime import datetime
import base64
import json
import os
import re
import urllib.error
import urllib.request

from flask import Flask, jsonify, request

app = Flask(__name__)

DOCUMENT_TYPE_ALIASES = {
    "driver_license": "DRIVING_LICENSE",
    "driving_license": "DRIVING_LICENSE",
    "commercial_registration": "COMMERCIAL_REGISTER",
    "commercial_register": "COMMERCIAL_REGISTER",
    "permit": "COMMERCIAL_REGISTER",
    "tax_card": "TAX_CARD",
}

DOCUMENT_KEYWORDS = {
    "DRIVING_LICENSE": [
        "driving license",
        "driver license",
        "license no",
        "categories of vehicle",
        "traffic department",
        "رخصة القيادة",
        "رخصة قياده",
        "إدارة المرور",
        "الادارة العامة للمرور",
    ],
    "COMMERCIAL_REGISTER": [
        "commercial register",
        "commercial registration",
        "registration no",
        "company name",
        "business name",
        "السجل التجاري",
        "مستخرج من السجل التجاري",
        "رقم القيد",
        "الاسم التجاري",
    ],
    "TAX_CARD": [
        "tax card",
        "tax registration",
        "tax number",
        "مصلحة الضرائب المصرية",
        "البطاقة الضريبية",
        "رقم التسجيل الضريبي",
        "النشاط",
    ],
}

ROLE_ALLOWED_DOCUMENTS = {
    "driver": {"DRIVING_LICENSE"},
    "workshop": {"COMMERCIAL_REGISTER"},
}


def _normalize(value=""):
    return (
        str(value)
        .lower()
        .replace("أ", "ا")
        .replace("إ", "ا")
        .replace("آ", "ا")
        .replace("ة", "ه")
        .replace("ى", "ي")
        .strip()
    )


@app.get("/health")
def health():
    return jsonify(
        {
            "success": True,
            "message": "CV verification service is running",
            "service": "salahny-cv-service",
            "geminiConfigured": bool(os.getenv("GEMINI_API_KEY")),
        }
    )


def _decode_text(file_bytes):
    """Fallback only for plain-text test files. Real images/PDFs need Gemini Vision."""
    try:
        text = file_bytes.decode("utf-8", errors="ignore")
    except Exception:
        return ""

    # Binary images decoded as UTF-8 produce mostly junk. Avoid treating that as OCR text.
    printable = sum(ch.isprintable() or ch.isspace() for ch in text)
    if not text or printable / max(len(text), 1) < 0.75:
        return ""
    return text.strip()


def _json_from_text(text):
    if not text:
        return {}
    cleaned = text.strip()
    cleaned = re.sub(r"^```(?:json)?\s*", "", cleaned, flags=re.I)
    cleaned = re.sub(r"\s*```$", "", cleaned)
    match = re.search(r"\{.*\}", cleaned, flags=re.S)
    if match:
        cleaned = match.group(0)
    try:
        return json.loads(cleaned)
    except json.JSONDecodeError:
        return {"extractedText": text}


def _call_gemini_vision(file_bytes, mimetype, role, declared_document_type):
    api_key = os.getenv("GEMINI_API_KEY")
    if not api_key:
        return {"ok": False, "error": "GEMINI_API_KEY is not configured"}

    model = os.getenv("GEMINI_VISION_MODEL") or os.getenv("GEMINI_MODEL") or "gemini-2.0-flash"
    url = (
        "https://generativelanguage.googleapis.com/v1beta/models/"
        + model
        + ":generateContent?key="
        + api_key
    )

    prompt = f"""
You are an OCR and document-verification engine for Salahny.
Read the uploaded document image/PDF and return ONLY valid JSON.
User role: {role}
Declared document type: {declared_document_type}

Required JSON keys:
- extractedText: all readable text, preserving Arabic/English.
- documentType: one of DRIVING_LICENSE, COMMERCIAL_REGISTER, TAX_CARD, UNKNOWN.
- ocrConfidence: number from 0 to 1 based on readability.
- extractedFields: object with any detected fields such as fullName, licenseNumber,
  expirationDate, companyName, registrationNumber, taxNumber, address, activityType.
- issues: array of short issues if the document is unclear, mismatched, expired, or unreadable.
""".strip()

    body = {
        "contents": [
            {
                "role": "user",
                "parts": [
                    {"text": prompt},
                    {
                        "inlineData": {
                            "mimeType": mimetype or "application/octet-stream",
                            "data": base64.b64encode(file_bytes).decode("ascii"),
                        }
                    },
                ],
            }
        ],
        "generationConfig": {"temperature": 0.0, "maxOutputTokens": 1400},
    }

    request_obj = urllib.request.Request(
        url,
        data=json.dumps(body).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    try:
        with urllib.request.urlopen(request_obj, timeout=int(os.getenv("GEMINI_TIMEOUT_SECONDS", "18"))) as response:
            payload = json.loads(response.read().decode("utf-8"))
    except urllib.error.HTTPError as exc:
        details = exc.read().decode("utf-8", errors="ignore")[:500]
        return {"ok": False, "error": f"Gemini HTTP {exc.code}: {details}"}
    except Exception as exc:
        return {"ok": False, "error": f"Gemini unavailable: {exc}"}

    text_parts = []
    for candidate in payload.get("candidates", []):
        for part in candidate.get("content", {}).get("parts", []):
            if part.get("text"):
                text_parts.append(part["text"])

    parsed = _json_from_text("\n".join(text_parts))
    parsed["verifier"] = "gemini_vision"
    return {"ok": True, "payload": parsed}


def _declared_type(document_type):
    return DOCUMENT_TYPE_ALIASES.get(_normalize(document_type).replace(" ", "_"), "UNKNOWN")


def _classify_text(text, declared_document_type=""):
    normalized_text = _normalize(text)
    best_type = "UNKNOWN"
    best_hits = []

    for doc_type, keywords in DOCUMENT_KEYWORDS.items():
        hits = [kw for kw in keywords if _normalize(kw) in normalized_text]
        if len(hits) > len(best_hits):
            best_type = doc_type
            best_hits = hits

    if best_type == "UNKNOWN":
        best_type = _declared_type(declared_document_type)

    confidence = 0.0 if best_type == "UNKNOWN" else min(0.9, 0.35 + len(best_hits) * 0.12)
    return best_type, best_hits, confidence


def _extract_field(text, patterns):
    for pattern in patterns:
        match = re.search(pattern, text, flags=re.I | re.M)
        if match and match.group(1):
            return re.sub(r"\s{2,}", " ", match.group(1).strip())
    return None


def _extract_fields(text, document_type, role):
    fields = {}
    if document_type == "DRIVING_LICENSE":
        fields["fullName"] = _extract_field(text, [r"(?:full\s*name|name|الاسم)\s*[:\-]?\s*([^\n]{3,100})"])
        fields["licenseNumber"] = _extract_field(text, [
            r"(?:license\s*(?:no|number)?|رقم\s*الرخصة)\s*[:\-#]?\s*([a-z0-9٠-٩\-]{5,30})",
            r"\b([0-9]{10,16})\b",
        ])
        fields["expirationDate"] = _extract_field(text, [
            r"(?:date\s*of\s*expiry|expiry|expires|تاريخ\s*الانتهاء|صالحة\s*حتى)\s*[:\-]?\s*([0-9٠-٩/\-]{6,20})"
        ])
    elif document_type == "COMMERCIAL_REGISTER":
        fields["companyName"] = _extract_field(text, [
            r"(?:company\s*name|business\s*name|الاسم\s*التجاري|اسم\s*الشركة)\s*[:\-]?\s*([^\n]{3,100})"
        ])
        fields["registrationNumber"] = _extract_field(text, [
            r"(?:commercial\s*(?:register|registration)\s*(?:no|number)?|رقم\s*القيد|رقم\s*السجل\s*التجاري)\s*[:\-#]?\s*([0-9٠-٩\-]{3,30})"
        ])
        fields["address"] = _extract_field(text, [r"(?:address|العنوان|عنوان\s*المحل)\s*[:\-]?\s*([^\n]{6,140})"])
        fields["activityType"] = _extract_field(text, [r"(?:activity|النشاط)\s*[:\-]?\s*([^\n]{3,100})"])
    elif document_type == "TAX_CARD":
        fields["taxNumber"] = _extract_field(text, [
            r"(?:tax\s*(?:registration)?\s*(?:no|number)?|رقم\s*التسجيل\s*الضريبي)\s*[:\-#]?\s*([0-9٠-٩]{6,30})"
        ])
        fields["businessName"] = _extract_field(text, [
            r"(?:business\s*name|اسم\s*الممول|اسم\s*الشركة)\s*[:\-]?\s*([^\n]{3,80})"
        ])
        fields["activityType"] = _extract_field(text, [r"(?:activity|النشاط)\s*[:\-]?\s*([^\n]{3,100})"])

    return {k: v for k, v in fields.items() if v}


def _merge_fields(*sources):
    merged = {}
    for source in sources:
        if isinstance(source, dict):
            for key, value in source.items():
                if value not in (None, "", [], {}):
                    merged[key] = value
    return merged


@app.post("/verify-document")
def verify_document():
    uploaded = request.files.get("file")
    role = request.form.get("role", "")
    document_type = request.form.get("documentType", "")
    if uploaded is None or role not in {"driver", "workshop"}:
        return jsonify({"success": False, "message": "file and valid role are required"}), 400

    raw = uploaded.read()
    mimetype = uploaded.mimetype or "application/octet-stream"
    issues = []

    gemini_result = _call_gemini_vision(raw, mimetype, role, document_type)
    if gemini_result.get("ok"):
        payload = gemini_result.get("payload") or {}
        text = str(payload.get("extractedText") or "").strip()
        verifier = payload.get("verifier", "gemini_vision")
        gemini_fields = payload.get("extractedFields") if isinstance(payload.get("extractedFields"), dict) else {}
        issues.extend([str(item) for item in payload.get("issues", []) if item])
        gemini_document_type = str(payload.get("documentType") or "UNKNOWN").upper()
        gemini_ocr_confidence = payload.get("ocrConfidence")
    else:
        text = _decode_text(raw)
        verifier = "plain_text_fallback"
        gemini_fields = {}
        gemini_document_type = "UNKNOWN"
        gemini_ocr_confidence = None
        issues.append(gemini_result.get("error") or "Vision OCR unavailable")

    detected_from_text, matched_keywords, keyword_confidence = _classify_text(text, document_type)
    detected_type = (
        gemini_document_type
        if gemini_document_type in DOCUMENT_KEYWORDS
        else detected_from_text
    )

    try:
        ocr_confidence = float(gemini_ocr_confidence)
    except (TypeError, ValueError):
        ocr_confidence = 0.0 if not text else min(0.75, 0.35 + len(text) / 1200)

    fields = _merge_fields(_extract_fields(text, detected_type, role), gemini_fields)

    if len(raw) < 1024:
        issues.append("Document file is too small or empty")
    if not text:
        issues.append("OCR could not read text from this document")
    if detected_type == "UNKNOWN":
        issues.append("Document type could not be detected from OCR text")
    elif detected_type not in ROLE_ALLOWED_DOCUMENTS.get(role, set()):
        issues.append(
            "Workshop verification accepts only Commercial Register documents"
            if role == "workshop"
            else "Driver verification accepts only Driving License documents"
        )

    confidence = max(keyword_confidence, ocr_confidence)
    if fields:
        confidence = max(confidence, min(0.96, 0.45 + len(fields) * 0.12 + len(matched_keywords) * 0.08))
    confidence = min(0.99, max(0.0, confidence))

    blocking_issue = any(
        phrase in issue.lower()
        for issue in issues
        for phrase in ["unreadable", "could not read", "could not be detected", "accepts only", "too small"]
    )

    if blocking_issue:
        status = "ai_rejected" if not text or detected_type == "UNKNOWN" else "needs_admin_review"
        is_valid = False
    elif confidence >= 0.75:
        status = "ai_verified"
        is_valid = True
    else:
        status = "needs_admin_review"
        is_valid = False

    return jsonify(
        {
            "success": True,
            "documentType": document_type,
            "detectedDocumentType": detected_type,
            "isValid": is_valid,
            "confidence": round(confidence, 2),
            "ocrConfidence": round(ocr_confidence, 2),
            "extractedText": text,
            "extractedFields": fields,
            "matchedKeywords": matched_keywords,
            "issues": sorted(set(issues)),
            "status": status,
            "verifier": verifier,
            "checkedAt": datetime.utcnow().isoformat() + "Z",
        }
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "5002")))
