const fallbackResult = (issues = ['Computer vision service is unavailable']) => ({
  success: false,
  isValid: false,
  confidence: 0,
  extractedFields: {},
  issues,
  status: 'needs_admin_review',
});

const localDocumentCheck = ({ file, role, documentType, issues = [] }) => {
  const name = file.originalname?.toLowerCase() || '';
  const text = file.buffer.toString('utf8').toLowerCase();
  const content = `${name} ${text}`;
  const expectedTerms =
    role === 'workshop'
      ? ['permit', 'license', 'registration', 'workshop', 'business', 'commercial']
      : ['driver', 'license', 'licence'];
  const matchedTerms = expectedTerms.filter((term) => content.includes(term));
  const hasReasonableSize = file.size >= 24 || file.buffer.length >= 24;
  const hasExpectedNameOrText = matchedTerms.length > 0;
  const imageOrPdf = ['image/jpeg', 'image/png', 'application/pdf'].includes(file.mimetype);
  const confidence = Math.min(
    0.82,
    0.35 +
      (imageOrPdf ? 0.15 : 0) +
      (hasReasonableSize ? 0.15 : 0) +
      Math.min(matchedTerms.length, 3) * 0.09,
  );

  const resultIssues = [...issues];
  if (!hasReasonableSize) resultIssues.push('Uploaded file is too small for reliable automated verification');
  if (!hasExpectedNameOrText) {
    resultIssues.push('Could not confidently detect expected document keywords');
  }

  const isValid = imageOrPdf && hasReasonableSize && hasExpectedNameOrText;
  return {
    success: true,
    isValid,
    confidence,
    extractedFields: {
      documentType,
      role,
      fileName: file.originalname,
      mimeType: file.mimetype,
      matchedTerms,
      verifier: 'local_cv_fallback',
    },
    issues: resultIssues,
    status: isValid && confidence >= 0.55 ? 'ai_verified' : 'needs_admin_review',
  };
};

const expandRailwayPrivateUrl = (url) => {
  if (!url) return [];
  const clean = url.replace(/\/$/, '');
  const withProtocol = /^https?:\/\//i.test(clean) ? clean : `http://${clean}`;
  const candidates = [withProtocol];
  try {
    const parsed = new URL(withProtocol);
    if (parsed.hostname.endsWith('.railway.internal') && !parsed.port) {
      const port = process.env.CV_SERVICE_PORT || '8080';
      parsed.port = port;
      candidates.push(parsed.toString().replace(/\/$/, ''));
    }
  } catch {
    // Ignore malformed optional fallback URLs; the fetch loop records real failures.
  }
  return candidates;
};

export const verifyDocumentWithCv = async ({ file, role, documentType }) => {
  const candidateUrls = [
    ...expandRailwayPrivateUrl(process.env.CV_SERVICE_URL),
    ...expandRailwayPrivateUrl(process.env.CV_SERVICE_FALLBACK_URL),
    ...expandRailwayPrivateUrl('http://salahny-cv.railway.internal'),
    ...expandRailwayPrivateUrl('http://salahny-app.railway.internal'),
    ...expandRailwayPrivateUrl('https://salahny-cv-production.up.railway.app'),
  ];

  if (candidateUrls.length === 0) {
    return localDocumentCheck({
      file,
      role,
      documentType,
      issues: ['CV_SERVICE_URL is not configured; used local document heuristic'],
    });
  }

  const buildBody = () => {
    const body = new FormData();
    body.append('file', new Blob([file.buffer], { type: file.mimetype }), file.originalname);
    body.append('role', role);
    body.append('documentType', documentType);
    return body;
  };

  const failures = [];
  for (const url of [...new Set(candidateUrls)]) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), Number(process.env.CV_TIMEOUT_MS) || 8000);
    try {
      const response = await fetch(`${url}/verify-document`, {
        method: 'POST',
        body: buildBody(),
        signal: controller.signal,
      });
      if (!response.ok) {
        failures.push(`${url} returned HTTP ${response.status}`);
        continue;
      }
      const payload = await response.json();
      return {
        success: payload.success === true,
        isValid: payload.isValid === true,
        confidence: Number(payload.confidence) || 0,
        extractedFields: {
          ...(payload.extractedFields ?? {}),
          verifier: 'external_cv_service',
          cvServiceUrl: url.replace(/\/\/.*@/, '//***@'),
        },
        issues: Array.isArray(payload.issues) ? payload.issues.map(String) : [],
        status: [
          'ai_verified',
          'ai_rejected',
          'needs_admin_review',
        ].includes(payload.status)
          ? payload.status
          : 'needs_admin_review',
      };
    } catch (error) {
      failures.push(`${url} unavailable`);
    } finally {
      clearTimeout(timer);
    }
  }

  return localDocumentCheck({
    file,
    role,
    documentType,
    issues: [
      'Computer vision service is unavailable; used local document heuristic',
      ...failures.slice(0, 3),
    ],
  });
};
