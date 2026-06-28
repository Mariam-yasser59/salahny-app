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

SUSPICIOUS_FAKE_MARKERS = [
    "test document",
    "not official",
    "generic test card",
    "for testing purposes only",
    "sample document",
    "mock document",
    "placeholder",
    "testland",
    "chatgpt",
    "openai",
    "dall-e",
    "dalle",
    "digitalSourceType",
    "digital source type",
    "trainedAlgo",
    "trained algorithm",
    "ai generated",
    "generated image",
    "synthetic",
]

def _fake_markers(text):
    normalized = _normalize(text)
    hits = []
    for marker in SUSPICIOUS_FAKE_MARKERS:
        if _normalize(marker) in normalized:
            hits.append(marker)
    return hits


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
- issues: array of short issues if the document is unclear, mismatched, expired, unofficial, synthetic, test/mock, or unreadable.

Hard rejection rules:
- If the document says TEST DOCUMENT, NOT OFFICIAL, Generic Test Card, For Testing Purposes Only, Sample, Mock, Placeholder, Testland, ChatGPT, OpenAI, AI-generated, DALL-E, trainedAlgo, digitalSourceType, or any similar synthetic/test marker, set documentType to UNKNOWN, ocrConfidence <= 0.25, and add an issue: "Synthetic/test/unofficial document detected".
- Do not classify a generic card as DRIVING_LICENSE just because it contains the words "License Number". Look for official document context too, such as traffic authority wording, driving license title, government authority wording, or Arabic equivalents.
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


def _clamp_score(value, low=0.0, high=0.99):
    return max(low, min(high, float(value)))


def _field_strength(document_type, fields):
    """Score how much useful structured data was extracted from the document."""
    if not fields:
        return 0.0, []

    normalized_fields = {key: value for key, value in fields.items() if value not in (None, "", [], {})}
    present = set(normalized_fields.keys())
    reasons = []
    score = min(0.14, len(present) * 0.035)

    critical_fields = {
        "DRIVING_LICENSE": ["licenseNumber", "fullName", "expirationDate"],
        "COMMERCIAL_REGISTER": ["registrationNumber", "companyName", "activityType", "address"],
        "TAX_CARD": ["taxNumber", "businessName", "activityType", "issueDate"],
    }.get(document_type, [])

    critical_hits = [field for field in critical_fields if field in present]
    score += min(0.14, len(critical_hits) * 0.055)
    if critical_hits:
        reasons.append("critical fields found: " + ", ".join(critical_hits))

    return _clamp_score(score, 0, 0.26), reasons


def _issue_penalty(issues):
    penalty = 0.0
    for issue in issues:
        normalized = _normalize(issue)
        if any(marker in normalized for marker in ["synthetic", "test/unofficial", "not official", "generated"]):
            penalty += 0.65
        elif any(marker in normalized for marker in ["could not read", "unreadable", "too small", "empty"]):
            penalty += 0.35
        elif any(marker in normalized for marker in ["could not be detected", "accepts only"]):
            penalty += 0.28
        elif any(marker in normalized for marker in ["expired", "unclear", "low", "glare", "blur"]):
            penalty += 0.12
        else:
            penalty += 0.04
    return _clamp_score(penalty, 0, 0.75)


def _professional_score(*, document_type, role, text, fields, matched_keywords, ocr_confidence, fake_markers, issues):
    """Dynamic verification score instead of fixed 75%/25% buckets."""
    text = text or ""
    try:
        ocr = _clamp_score(float(ocr_confidence), 0, 1)
    except (TypeError, ValueError):
        ocr = 0.0

    allowed = document_type in ROLE_ALLOWED_DOCUMENTS.get(role, set())
    field_score, field_reasons = _field_strength(document_type, fields)
    keyword_score = min(0.18, len(matched_keywords or []) * 0.055)
    text_score = min(0.08, len(text.strip()) / 2500)
    type_score = 0.18 if document_type != "UNKNOWN" else 0.0
    role_score = 0.12 if allowed else 0.0
    ocr_score = ocr * 0.34
    penalty = _issue_penalty(issues)

    score = 0.08 + ocr_score + type_score + role_score + keyword_score + field_score + text_score - penalty
    score = _clamp_score(score)

    if fake_markers:
        score = min(score, 0.24)
    if not text.strip():
        score = min(score, 0.18)
    if document_type == "UNKNOWN":
        score = min(score, 0.49)
    if not allowed and document_type != "UNKNOWN":
        score = min(score, 0.42)

    breakdown = {
        "ocr": round(ocr_score, 3),
        "documentType": round(type_score, 3),
        "roleMatch": round(role_score, 3),
        "keywords": round(keyword_score, 3),
        "fields": round(field_score, 3),
        "textLength": round(text_score, 3),
        "penalty": round(penalty, 3),
        "fieldReasons": field_reasons,
    }
    return round(score, 2), breakdown


def _critical_fields_found(document_type, fields):
    field_set = set((fields or {}).keys())
    required = {
        "DRIVING_LICENSE": {"licenseNumber", "fullName"},
        "COMMERCIAL_REGISTER": {"registrationNumber", "companyName"},
        "TAX_CARD": {"taxNumber", "businessName"},
    }.get(document_type, set())
    if not required:
        return False
    return len(field_set.intersection(required)) >= 1


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

    fake_markers = _fake_markers(text)
    if fake_markers:
        issues.append("Synthetic/test/unofficial document detected: " + ", ".join(fake_markers[:5]))
        # A test/mock/unofficial/generated document must never be auto-verified.
        detected_type = "UNKNOWN"
        fields = {}
        ocr_confidence = min(ocr_confidence, 0.25)

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

    confidence, score_breakdown = _professional_score(
        document_type=detected_type,
        role=role,
        text=text,
        fields=fields,
        matched_keywords=matched_keywords,
        ocr_confidence=ocr_confidence,
        fake_markers=fake_markers,
        issues=issues,
    )

    blocking_reject = any(
        phrase in issue.lower()
        for issue in issues
        for phrase in [
            "synthetic",
            "test/unofficial",
            "not official",
            "too small",
            "empty",
        ]
    )
    hard_mismatch = any("accepts only" in issue.lower() for issue in issues)
    unreadable = not text.strip() or any("could not read" in issue.lower() for issue in issues)

    if blocking_reject or unreadable or hard_mismatch:
        status = "ai_rejected"
        is_valid = False
    elif confidence >= 0.82 and detected_type != "UNKNOWN" and _critical_fields_found(detected_type, fields):
        status = "ai_verified"
        is_valid = True
    elif confidence >= 0.45:
        status = "needs_admin_review"
        is_valid = False
    else:
        status = "ai_rejected"
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
            "scoreBreakdown": score_breakdown,
            "issues": sorted(set(issues)),
            "status": status,
            "verifier": verifier,
            "checkedAt": datetime.utcnow().isoformat() + "Z",
        }
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "5002")))
