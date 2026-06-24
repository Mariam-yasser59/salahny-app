import assert from 'node:assert/strict';

import { storeDocumentFile } from '../services/documentStorageService.js';
import { createPaymentIntent } from '../services/paymentProvider.js';

const originalFetch = global.fetch;
const originalEnv = {
  documentStorageProvider: process.env.DOCUMENT_STORAGE_PROVIDER,
  cloudName: process.env.CLOUDINARY_CLOUD_NAME,
  cloudKey: process.env.CLOUDINARY_API_KEY,
  cloudSecret: process.env.CLOUDINARY_API_SECRET,
  stripeSecret: process.env.STRIPE_SECRET_KEY,
};

try {
  process.env.DOCUMENT_STORAGE_PROVIDER = 'cloudinary';
  process.env.CLOUDINARY_CLOUD_NAME = 'demo';
  process.env.CLOUDINARY_API_KEY = 'key';
  process.env.CLOUDINARY_API_SECRET = 'secret';
  global.fetch = async () => new Response('failed', { status: 500 });

  const fallback = await storeDocumentFile({
    buffer: Buffer.from('license'),
    mimetype: 'application/pdf',
    originalname: 'license.pdf',
  });
  assert.equal(fallback.storageProvider, 'mongodb');
  assert.equal(fallback.data.toString(), 'license');

  process.env.STRIPE_SECRET_KEY = 'sk_test_demo';
  global.fetch = async (_url, options) => {
    assert.match(options.body.toString(), /amount=24900/);
    return Response.json({
      id: 'pi_demo',
      client_secret: 'pi_demo_secret',
      amount: 24900,
      currency: 'usd',
    });
  };
  const intent = await createPaymentIntent({
    amount: 249,
    metadata: { packageId: 'pkg-1' },
  });
  assert.equal(intent.id, 'pi_demo');
  assert.equal(intent.client_secret, 'pi_demo_secret');

  console.log('provider readiness checks passed');
} finally {
  global.fetch = originalFetch;
  process.env.DOCUMENT_STORAGE_PROVIDER = originalEnv.documentStorageProvider;
  process.env.CLOUDINARY_CLOUD_NAME = originalEnv.cloudName;
  process.env.CLOUDINARY_API_KEY = originalEnv.cloudKey;
  process.env.CLOUDINARY_API_SECRET = originalEnv.cloudSecret;
  process.env.STRIPE_SECRET_KEY = originalEnv.stripeSecret;
}
