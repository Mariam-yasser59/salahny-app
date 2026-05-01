const ML_URL = process.env.ML_SERVICE_URL || 'http://127.0.0.1:5001';

export const predictWithMlModel = async (sensorReadings) => {
  const response = await fetch(`${ML_URL}/predict`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ sensor_readings: sensorReadings }),
  });

  if (!response.ok) {
    const payload = await response.json().catch(() => ({}));
    throw new Error(payload.error || `ML service failed with ${response.status}`);
  }

  return response.json();
};

export const mlHealth = async () => {
  const response = await fetch(`${ML_URL}/health`);
  if (!response.ok) {
    throw new Error(`ML health failed with ${response.status}`);
  }
  return response.json();
};
