import 'dotenv/config';

import cors from 'cors';
import express from 'express';
import rateLimit from 'express-rate-limit';
import mongoSanitize from 'express-mongo-sanitize';
import helmet from 'helmet';
import morgan from 'morgan';

import authRoutes from './routes/authRoutes.js';
import adminRoutes from './routes/adminRoutes.js';
import bookingRoutes from './routes/bookingRoutes.js';
import catalogRoutes from './routes/catalogRoutes.js';
import chatRoutes from './routes/chatRoutes.js';
import chatbotRoutes from './routes/chatbotRoutes.js';
import contentRoutes from './routes/contentRoutes.js';
import diagnosticRoutes from './routes/diagnosticRoutes.js';
import documentRoutes from './routes/documentRoutes.js';
import directMessageRoutes from './routes/directMessageRoutes.js';
import emergencyRoutes from './routes/emergencyRoutes.js';
import notificationRoutes from './routes/notificationRoutes.js';
import paymentRoutes from './routes/paymentRoutes.js';
import publicRoutes from './routes/publicRoutes.js';
import reviewRoutes from './routes/reviewRoutes.js';
import subscriptionRoutes from './routes/subscriptionRoutes.js';
import userRoutes from './routes/userRoutes.js';
import workshopPortalRoutes from './routes/workshopPortalRoutes.js';
import workshopRoutes from './routes/workshopRoutes.js';
import vehicleRoutes from './routes/vehicleRoutes.js';
import verificationRoutes from './routes/verificationRoutes.js';
import trackingRoutes from './routes/trackingRoutes.js';
import { errorHandler, notFound } from './middleware/errorMiddleware.js';
import { getEmailProviderStatus, sendEmail } from './services/emailService.js';

const app = express();

const allowedOrigins = (process.env.CORS_ORIGINS || '')
  .split(',')
  .map((origin) => origin.trim())
  .filter(Boolean);

app.set('trust proxy', 1);
app.use(helmet());
app.use(
  cors({
    origin(origin, callback) {
      if (!origin || allowedOrigins.length === 0 || allowedOrigins.includes(origin)) {
        return callback(null, true);
      }
      return callback(new Error('CORS origin denied'));
    },
  }),
);
app.use(express.json({ limit: '1mb' }));
app.use(express.urlencoded({ extended: true, limit: '1mb' }));
app.use(mongoSanitize());
app.use(
  rateLimit({
    windowMs: 15 * 60 * 1000,
    limit: Number(process.env.RATE_LIMIT_MAX) || 300,
    standardHeaders: true,
    legacyHeaders: false,
  }),
);
if (process.env.NODE_ENV !== 'test') {
  app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));
}

app.get('/api/health', (_req, res) => {
  res.status(200).json({
    success: true,
    message: 'Salahny API is running',
  });
});

app.get('/api/version', (_req, res) => {
  res.status(200).json({
    success: true,
    data: {
      commit:
        process.env.RAILWAY_GIT_COMMIT_SHA ||
        process.env.GIT_COMMIT_SHA ||
        process.env.SOURCE_VERSION ||
        'unknown',
      environment: process.env.NODE_ENV || 'development',
      deployedAt: process.env.DEPLOYED_AT || null,
    },
  });
});

app.get('/api/providers', (_req, res) => {
  const mlConfigured = Boolean(process.env.ML_SERVICE_URL || process.env.ML_SERVICE_HOSTPORT);
  const cvConfigured = Boolean(process.env.CV_SERVICE_URL);
  const googleClientIds = (
    process.env.GOOGLE_CLIENT_IDS ||
    process.env.GOOGLE_CLIENT_ID ||
    ''
  )
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);
  const paymentProvider = process.env.PAYMENT_PROVIDER || 'simulated';
  const stripeSecretConfigured = Boolean(process.env.STRIPE_SECRET_KEY);
  const stripePublishableConfigured = Boolean(process.env.STRIPE_PUBLISHABLE_KEY);

  res.status(200).json({
    success: true,
    data: {
      email: getEmailProviderStatus(),
      ml: {
        configured: mlConfigured,
      },
      computerVision: {
        configured: cvConfigured,
        mode: cvConfigured ? 'external_service' : 'local_document_heuristic_fallback',
        },
        googleLogin: {
          configured: googleClientIds.length > 0,
          clientCount: googleClientIds.length,
        },
      geminiChatbot: {
        configured: Boolean(process.env.GEMINI_API_KEY),
        model: process.env.GEMINI_MODEL || 'gemini-2.0-flash',
        },
        payments: {
          provider: paymentProvider,
          stripeConfigured:
            paymentProvider === 'stripe' &&
            stripeSecretConfigured &&
            stripePublishableConfigured,
          stripeSecretConfigured,
          stripePublishableConfigured,
        },
      maps: {
        mobileGoogleMapsRequiresBuildKey: true,
        flutterMapFallbackAvailable: true,
      },
    },
  });
});

app.use('/api/auth', authRoutes);
app.use('/api/public', publicRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/chat', chatRoutes);
app.use('/api/chatbot', chatbotRoutes);
app.use('/api/content', contentRoutes);
app.use('/api/users', userRoutes);
app.use('/api/workshops', workshopRoutes);
app.use('/api/workshop-portal', workshopPortalRoutes);
app.use('/api/bookings', bookingRoutes);
app.use('/api/reviews', reviewRoutes);
app.use('/api/diagnostics', diagnosticRoutes);
app.use('/api/documents', documentRoutes);
app.use('/api/verification', verificationRoutes);
app.use('/api/direct-messages', directMessageRoutes);
app.use('/api/emergency', emergencyRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/payments', paymentRoutes);
app.use('/api/subscriptions', subscriptionRoutes);
app.use('/api/vehicles', vehicleRoutes);
app.use('/api/tracking', trackingRoutes);
app.use('/api', catalogRoutes);

if (process.env.ENABLE_DEBUG_ROUTES === 'true') {
  app.post('/api/debug/send-test-email', async (req, res) => {
    if (!process.env.DEBUG_EMAIL_TOKEN) {
      return res.status(503).json({
        success: false,
        message: 'Debug email endpoint requires DEBUG_EMAIL_TOKEN',
      });
    }
    const token = req.get('x-debug-token') || req.body.token;
    if (token !== process.env.DEBUG_EMAIL_TOKEN) {
      return res.status(403).json({ success: false, message: 'Forbidden' });
    }
    const result = await sendEmail({
      to: req.body.to,
      subject: 'Salahny test email',
      text: 'This is a test email from Salahny.',
      html: '<p>This is a test email from Salahny.</p>',
    });
    res.status(result.sent ? 200 : 503).json({ success: result.sent, data: result });
  });
}

app.use(notFound);
app.use(errorHandler);

export default app;
