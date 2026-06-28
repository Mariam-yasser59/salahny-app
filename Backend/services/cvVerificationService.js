const ALLOWED_MIME_TYPES = ['image/jpeg', 'image/png', 'application/pdf'];
const MAX_FILE_SIZE_BYTES = 5 * 1024 * 1024;

const AR = {
  taxAuthority: '\u0645\u0635\u0644\u062d\u0629 \u0627\u0644\u0636\u0631\u0627\u0626\u0628 \u0627\u0644\u0645\u0635\u0631\u064a\u0629',
  taxCard: '\u0627\u0644\u0628\u0637\u0627\u0642\u0629 \u0627\u0644\u0636\u0631\u064a\u0628\u064a\u0629',
  taxNumber: '\u0631\u0642\u0645 \u0627\u0644\u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u0636\u0631\u064a\u0628\u064a',
  activity: '\u0627\u0644\u0646\u0634\u0627\u0637',
  commercialRegister: '\u0627\u0644\u0633\u062c\u0644 \u0627\u0644\u062a\u062c\u0627\u0631\u064a',
  commercialExtract: '\u0645\u0633\u062a\u062e\u0631\u062c \u0645\u0646 \u0627\u0644\u0633\u062c\u0644 \u0627\u0644\u062a\u062c\u0627\u0631\u064a',
  nationalFacilityNumber: '\u0627\u0644\u0631\u0642\u0645 \u0627\u0644\u0642\u0648\u0645\u064a \u0644\u0644\u0645\u0646\u0634\u0623\u0629',
  tradeName: '\u0627\u0644\u0627\u0633\u0645 \u0627\u0644\u062a\u062c\u0627\u0631\u064a',
  drivingLicense: '\u0631\u062e\u0635\u0629 \u0627\u0644\u0642\u064a\u0627\u062f\u0629',
  drivingLicenseAlt: '\u0631\u062e\u0635\u0629 \u0642\u064a\u0627\u062f\u0647',
  trafficDept: '\u0625\u062f\u0627\u0631\u0629 \u0627\u0644\u0645\u0631\u0648\u0631',
  generalTrafficDept: '\u0627\u0644\u0625\u062f\u0627\u0631\u0629 \u0627\u0644\u0639\u0627\u0645\u0629 \u0644\u0644\u0645\u0631\u0648\u0631',
};

const DOCUMENT_RULES = {
  TAX_CARD: {
    aliases: ['tax_card', 'business_license', 'tax_card_supporting'],
    keywords: [
      AR.taxAuthority,
      AR.taxCard,
      AR.taxNumber,
      AR.activity,
      'tax card',
      'tax registration',
    ],
  },
  COMMERCIAL_REGISTER: {
    aliases: ['commercial_registration', 'commercial_register', 'permit'],
    keywords: [
      AR.commercialRegister,
      AR.commercialExtract,
      AR.nationalFacilityNumber,
      AR.tradeName,
      'commercial register',
      'commercial registration',
    ],
  },
  DRIVING_LICENSE: {
    aliases: ['driver_license', 'driving_license'],
    keywords: [
      AR.drivingLicense,
      AR.drivingLicenseAlt,
      'driving license',
      AR.trafficDept,
      AR.generalTrafficDept,
      'categories of vehicle',
    ],
  },
};

const ROLE_ALLOWED_DOCUMENTS = {
  workshop: ['COMMERCIAL_REGISTER'],
  driver: ['DRIVING_LICENSE'],
};

const normalize = (value = '') =>
  value
    .toString()
    .toLowerCase()
    .replace(/[\u0623\u0625\u0622]/g, '\u0627')
    .replace(/\u0629/g, '\u0647')
    .replace(/\u0649/g, '\u064a')
    .replace(/\s+/g, ' ')
    .trim();

const unique = (items) => [...new Set(items.filter(Boolean))];

const keywordHits = (text, keywords) => {
  const normalizedText = normalize(text);
  return keywords.filter((keyword) => normalizedText.includes(normalize(keyword)));
};

export const classifyDocumentText = (text = '') => {
  const matches = Object.entries(DOCUMENT_RULES).map(([documentType, rule]) => {
    const hits = keywordHits(text, rule.keywords);
    return { documentType, hits, score: hits.length / rule.keywords.length };
  });

  matches.sort((a, b) => b.hits.length - a.hits.length || b.score - a.score);
  const best = matches[0];
  if (!best || best.hits.length === 0) {
    return {
      documentType: 'UNKNOWN',
      matchedKeywords: [],
      confidence: text.trim().length >= 20 ? 0.18 : 0,
    };
  }

  return {
    documentType: best.documentType,
    matchedKeywords: best.hits,
    confidence: Math.min(0.96, 0.35 + best.hits.length * 0.15),
  };
};

const classifyFromDeclaredKind = (documentType) => {
  const normalized = normalize(documentType).replace(/\s/g, '_');
  const entry = Object.entries(DOCUMENT_RULES).find(([, rule]) =>
    rule.aliases.includes(normalized),
  );
  return entry?.[0] ?? 'UNKNOWN';
};

const extractField = (text, patterns) => {
  for (const pattern of patterns) {
    const match = text.match(pattern);
    if (match?.[1]) return match[1].trim().replace(/\s{2,}/g, ' ');
  }
  return null;
};

export const extractStructuredFields = (documentType, text = '') => {
  const clean = text.replace(/\r/g, '\n');
  if (documentType === 'TAX_CARD') {
    return {
      businessName: extractField(clean, [
        /(?:\u0627\u0633\u0645 \u0627\u0644\u0645\u0645\u0648\u0644|\u0627\u0633\u0645 \u0627\u0644\u0634\u0631\u0643\u0629|business\s*name)\s*[:\-]?\s*([^\n]{3,80})/i,
      ]),
      taxNumber: extractField(clean, [
        /(?:\u0631\u0642\u0645 \u0627\u0644\u062a\u0633\u062c\u064a\u0644 \u0627\u0644\u0636\u0631\u064a\u0628\u064a|\u0631\u0642\u0645 \u0627\u0644\u062a\u0633\u062c\u064a\u0644|tax\s*(?:registration)?\s*(?:no|number)?)\s*[:\-]?\s*([0-9\u0660-\u0669]{6,30})/i,
      ]),
      activityType: extractField(clean, [
        /(?:\u0627\u0644\u0646\u0634\u0627\u0637|activity)\s*[:\-]?\s*([^\n]{3,100})/i,
      ]),
      issueDate: extractField(clean, [
        /(?:\u062a\u0627\u0631\u064a\u062e \u0627\u0644\u0627\u0635\u062f\u0627\u0631|issue\s*date)\s*[:\-]?\s*([0-9\u0660-\u0669\/\-]{6,20})/i,
      ]),
    };
  }

  if (documentType === 'COMMERCIAL_REGISTER') {
    return {
      companyName: extractField(clean, [
        /(?:\u0627\u0644\u0627\u0633\u0645 \u0627\u0644\u062a\u062c\u0627\u0631\u064a|\u0627\u0633\u0645 \u0627\u0644\u0634\u0631\u0643\u0629|company\s*name)\s*[:\-]?\s*([^\n]{3,100})/i,
      ]),
      registrationNumber: extractField(clean, [
        /(?:\u0631\u0642\u0645 \u0627\u0644\u0642\u064a\u062f|\u0631\u0642\u0645 \u0627\u0644\u0633\u062c\u0644 \u0627\u0644\u062a\u062c\u0627\u0631\u064a|commercial\s*(?:register|registration)\s*(?:no|number)?)\s*[:\-]?\s*([0-9\u0660-\u0669\-]{3,30})/i,
      ]),
      activityType: extractField(clean, [
        /(?:\u0646\u0648\u0639 \u0627\u0644\u062a\u062c\u0627\u0631\u0629|\u0627\u0644\u0646\u0634\u0627\u0637|activity)\s*[:\-]?\s*([^\n]{3,100})/i,
      ]),
      address: extractField(clean, [
        /(?:\u0627\u0644\u0639\u0646\u0648\u0627\u0646|\u0639\u0646\u0648\u0627\u0646 \u0627\u0644\u0645\u062d\u0644|address)\s*[:\-]?\s*([^\n]{6,140})/i,
      ]),
    };
  }

  if (documentType === 'DRIVING_LICENSE') {
    return {
      fullName: extractField(clean, [
        /(?:full\s*name|name|\u0627\u0644\u0627\u0633\u0645)\s*[:\-]?\s*([^\n]{3,100})/i,
      ]),
      licenseNumber: extractField(clean, [
        /(?:license\s*(?:no|number)?|\u0631\u0642\u0645 \u0627\u0644\u0631\u062e\u0635\u0629)\s*[:\-]?\s*([a-z0-9\u0660-\u0669\-]{5,30})/i,
        /\b([0-9]{10,16})\b/,
      ]),
      expirationDate: extractField(clean, [
        /(?:date\s*of\s*expiry|expiry|expires|\u062a\u0627\u0631\u064a\u062e \u0627\u0644\u0627\u0646\u062a\u0647\u0627\u0621|\u0635\u0627\u0644\u062d\u0629 \u062d\u062a\u0649)\s*[:\-]?\s*([0-9\u0660-\u0669\/\-]{6,20})/i,
      ]),
      nationality: extractField(clean, [
        /(?:nationality|\u0627\u0644\u062c\u0646\u0633\u064a\u0629)\s*[:\-]?\s*([^\n]{3,60})/i,
      ]),
    };
  }

  return {};
};

const compactObject = (value) =>
  Object.fromEntries(
    Object.entries(value).filter(([, item]) => item !== null && item !== ''),
  );

const expandRailwayPrivateUrl = (url) => {
  if (!url) return [];
  const clean = url.replace(/\/$/, '');
  const withProtocol = /^https?:\/\//i.test(clean) ? clean : `http://${clean}`;
  const candidates = [withProtocol];
  try {
    const parsed = new URL(withProtocol);
    if (parsed.hostname.endsWith('.railway.internal') && !parsed.port) {
      parsed.port = process.env.CV_SERVICE_PORT || '8080';
      candidates.push(parsed.toString().replace(/\/$/, ''));
    }
  } catch {
    // Optional provider URLs are validated by the fetch loop.
  }
  return candidates;
};

const callCvService = async ({ file, role, documentType }) => {
  const candidateUrls = [
    ...expandRailwayPrivateUrl(process.env.CV_SERVICE_URL),
    ...expandRailwayPrivateUrl(process.env.CV_SERVICE_FALLBACK_URL),
    ...(process.env.CV_SERVICE_USE_RAILWAY_INTERNAL === 'true'
      ? expandRailwayPrivateUrl('http://salahny-cv.railway.internal')
      : []),
  ];

  const failures = [];
  for (const url of unique(candidateUrls)) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), Number(process.env.CV_TIMEOUT_MS) || 12000);
    try {
      const body = new FormData();
      body.append('file', new Blob([file.buffer], { type: file.mimetype }), file.originalname);
      body.append('role', role);
      body.append('documentType', documentType);
      const response = await fetch(`${url}/verify-document`, {
        method: 'POST',
        body,
        signal: controller.signal,
      });
      if (!response.ok) {
        failures.push(`${url} returned HTTP ${response.status}`);
        continue;
      }
      const payload = await response.json();
      return {
        payload,
        failures,
        verifier: 'external_cv_service',
        cvServiceUrl: url.replace(/\/\/.*@/, '//***@'),
      };
    } catch {
      failures.push(`${url} unavailable`);
    } finally {
      clearTimeout(timer);
    }
  }

  return { payload: null, failures, verifier: 'local_rule_fallback' };
};

const validateRole = ({ role, documentType }) => {
  const allowed = ROLE_ALLOWED_DOCUMENTS[role] ?? [];
  if (documentType === 'UNKNOWN') {
    return 'Document type could not be detected from OCR text';
  }
  if (!allowed.includes(documentType)) {
    return role === 'workshop'
      ? 'Workshop verification accepts only Commercial Register as the primary verification document'
      : 'Driver verification accepts only Driving License documents';
  }
  return '';
};

export const verifyDocumentWithCv = async ({ file, role, documentType }) => {
  const issues = [];
  const size = file.size ?? file.buffer?.length ?? 0;
  if (!ALLOWED_MIME_TYPES.includes(file.mimetype)) {
    return {
      success: true,
      isValid: false,
      confidence: 0,
      ocrConfidence: 0,
      detectedDocumentType: 'UNKNOWN',
      extractedText: '',
      extractedFields: {},
      qualityStatus: 'unsupported',
      rejectionReason: 'Only JPEG, PNG, and PDF files are allowed',
      issues: ['Unsupported file type'],
      status: 'ai_rejected',
    };
  }

  if (!file.buffer?.length) issues.push('Uploaded file is missing or could not be read');
  if (size > MAX_FILE_SIZE_BYTES) issues.push('Uploaded file exceeds the maximum allowed size');
  if (size < 1024) issues.push('Uploaded file is too small or empty');
  if (file.buffer?.length >= 2 && file.buffer[0] === 0x4d && file.buffer[1] === 0x5a) {
    return {
      success: true,
      isValid: false,
      confidence: 0,
      ocrConfidence: 0,
      detectedDocumentType: 'UNKNOWN',
      extractedText: '',
      extractedFields: {},
      qualityStatus: 'unsupported',
      rejectionReason: 'Executable files are not allowed',
      issues: ['Executable file signature detected'],
      status: 'ai_rejected',
    };
  }

  const cv = await callCvService({ file, role, documentType });
  if (cv.failures?.length) issues.push(...cv.failures.slice(0, 2));
  if (!cv.payload) {
    issues.push('CV service is not configured or unavailable');
  }

  const extractedText = cv.payload?.extractedText?.toString?.() ?? '';
  const classificationFromOcr = classifyDocumentText(extractedText);
  const declaredType = classifyFromDeclaredKind(documentType);
  const serviceDetectedType =
    cv.payload?.detectedDocumentType?.toString?.().toUpperCase?.() ||
    cv.payload?.documentType?.toString?.().toUpperCase?.() ||
    'UNKNOWN';
  const detectedDocumentType =
    classificationFromOcr.documentType !== 'UNKNOWN'
      ? classificationFromOcr.documentType
      : ['DRIVING_LICENSE', 'COMMERCIAL_REGISTER', 'TAX_CARD'].includes(serviceDetectedType)
        ? serviceDetectedType
        : declaredType;

  const ocrConfidence = Number(cv.payload?.ocrConfidence);
  const confidence = Math.max(
    classificationFromOcr.confidence,
    Number(cv.payload?.confidence) || 0,
    Number.isFinite(ocrConfidence) ? ocrConfidence : 0,
  );

  const roleRejectionReason = validateRole({ role, documentType: detectedDocumentType });
  if (roleRejectionReason) issues.push(roleRejectionReason);
  if (!extractedText.trim()) issues.push('OCR could not read text from this document');
  if (confidence < 0.45) issues.push('OCR confidence is too low for automatic verification');

  const qualityStatus =
    issues.some((item) => item.toLowerCase().includes('unsupported'))
      ? 'unsupported'
      : !extractedText.trim() || issues.some((item) => item.toLowerCase().includes('empty'))
        ? 'unreadable'
        : confidence >= 0.65
          ? 'good'
          : 'poor';

  let status = 'needs_admin_review';
  let isValid = false;
  let rejectionReason = '';
  if (roleRejectionReason || qualityStatus === 'unsupported' || qualityStatus === 'unreadable') {
    status = 'ai_rejected';
    rejectionReason = roleRejectionReason || 'Document is unreadable or empty';
  } else if (confidence >= 0.75 && detectedDocumentType !== 'UNKNOWN') {
    status = 'ai_verified';
    isValid = true;
  }

  const extractedFields = compactObject({
    ...extractStructuredFields(detectedDocumentType, extractedText),
    ...(cv.payload?.extractedFields ?? {}),
    ...(Array.isArray(cv.payload?.matchedKeywords) ? { serviceMatchedKeywords: cv.payload.matchedKeywords } : {}),
    declaredKind: documentType,
    detectedDocumentType,
    matchedKeywords: classificationFromOcr.matchedKeywords,
    verifier: cv.verifier,
    cvServiceUrl: cv.cvServiceUrl,
  });

  return {
    success: true,
    isValid,
    confidence: Math.min(0.99, Math.max(0, Number(confidence.toFixed(2)))),
    ocrConfidence: Number.isFinite(ocrConfidence)
      ? Math.min(0.99, Math.max(0, Number(ocrConfidence.toFixed(2))))
      : null,
    detectedDocumentType,
    extractedText,
    extractedFields,
    qualityStatus,
    rejectionReason,
    issues: unique(issues),
    status,
  };
};
