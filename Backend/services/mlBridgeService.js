const expandRailwayPrivateUrl = (url) => {
  if (!url) return [];
  const clean = url.replace(/\/$/, '');
  const withProtocol = /^https?:\/\//i.test(clean) ? clean : `http://${clean}`;
  const candidates = [withProtocol];
  try {
    const parsed = new URL(withProtocol);
    if (parsed.hostname.endsWith('.railway.internal') && !parsed.port) {
      parsed.port = process.env.ML_SERVICE_PORT || '8080';
      candidates.push(parsed.toString().replace(/\/$/, ''));
    }
  } catch {
    // Ignore malformed optional URLs; requests below will report usable failures.
  }
  return candidates;
};

const mlCandidateUrls = () => [
  ...expandRailwayPrivateUrl(process.env.ML_SERVICE_URL),
  ...expandRailwayPrivateUrl(
    process.env.ML_SERVICE_HOSTPORT
      ? `http://${process.env.ML_SERVICE_HOSTPORT}`
      : '',
  ),
  ...expandRailwayPrivateUrl('http://salahny-ai.railway.internal'),
  ...expandRailwayPrivateUrl('https://salahny-ai-production.up.railway.app'),
];

export const predictWithMlModel = async (sensorReadings) => {
  const urls = [...new Set(mlCandidateUrls())];
  if (urls.length === 0) {
    throw new Error('ML_SERVICE_URL is not configured');
  }
  const failures = [];
  for (const url of urls) {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 8000);
    try {
      const response = await fetch(`${url}/predict`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ sensor_readings: sensorReadings }),
        signal: controller.signal,
      });

      if (!response.ok) {
        const payload = await response.json().catch(() => ({}));
        failures.push(`${url} returned ${payload.error || response.status}`);
        continue;
      }

      return response.json();
    } catch {
      failures.push(`${url} unavailable`);
    } finally {
      clearTimeout(timeout);
    }
  }
  throw new Error(failures.slice(0, 3).join('; ') || 'ML service unavailable');
};

export const mlHealth = async () => {
  const urls = [...new Set(mlCandidateUrls())];
  if (urls.length === 0) {
    throw new Error('ML_SERVICE_URL is not configured');
  }
  const failures = [];
  for (const url of urls) {
    try {
      const response = await fetch(`${url}/health`);
      if (!response.ok) {
        failures.push(`${url} health failed with ${response.status}`);
        continue;
      }
      return response.json();
    } catch {
      failures.push(`${url} unavailable`);
    }
  }
  throw new Error(failures.slice(0, 3).join('; ') || 'ML service unavailable');
};
