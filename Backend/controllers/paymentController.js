import PackagePurchase from '../models/PackagePurchase.js';
import ServicePackage from '../models/Package.js';
import mongoose from 'mongoose';
import asyncHandler from '../utils/asyncHandler.js';
import { logActivity } from '../utils/activityLogger.js';
import { createNotification } from './notificationController.js';
import {
  createPaymentIntent,
  getPaymentIntent,
  stripePublishableKey,
  stripeReady,
} from '../services/paymentProvider.js';

const mapPurchase = (purchase) => ({
  id: purchase._id.toString(),
  packageId: purchase.package?._id?.toString() ?? purchase.package?.toString() ?? '',
  packageName: purchase.packageName,
  amount: purchase.amount,
  currency: purchase.currency || 'EGP',
  method: purchase.method || purchase.paymentMethod,
  paymentMethod: purchase.paymentMethod,
  status: purchase.status,
  transactionId: purchase.transactionId || purchase.transactionRef,
  transactionRef: purchase.transactionRef,
  cardLast4: purchase.cardLast4 || '',
  startsAt: purchase.startsAt,
  endsAt: purchase.endsAt,
  isActive: ['paid', 'success'].includes(purchase.status) && purchase.endsAt > new Date(),
  createdAt: purchase.createdAt,
});

export const createDemoOnlineSubscriptionPayment = asyncHandler(async (req, res) => {
  const { planId, amount, cardLast4 } = req.body;

  if (!planId) {
    return res.status(400).json({ success: false, message: 'planId is required' });
  }
  if (!mongoose.isValidObjectId(planId)) {
    return res.status(400).json({ success: false, message: 'planId is invalid' });
  }
  if (!/^\d{4}$/.test(String(cardLast4 || ''))) {
    return res.status(400).json({
      success: false,
      message: 'cardLast4 must contain exactly 4 digits',
    });
  }

  const pkg = await ServicePackage.findOne({ _id: planId, isEnabled: { $ne: false } });
  if (!pkg) {
    return res.status(404).json({ success: false, message: 'Subscription plan not found' });
  }

  const requestedAmount = Number(amount);
  if (!Number.isFinite(requestedAmount) || requestedAmount <= 0) {
    return res.status(400).json({ success: false, message: 'Valid amount is required' });
  }
  if (Math.abs(requestedAmount - Number(pkg.price)) > 0.01) {
    return res.status(409).json({
      success: false,
      message: 'Payment amount does not match the selected subscription plan',
    });
  }

  const startsAt = new Date();
  const endsAt = new Date(
    startsAt.getTime() + pkg.durationMonths * 30 * 24 * 60 * 60 * 1000,
  );
  const transactionId = `DEMO-SUB-TXN-${Date.now()}`;

  const purchase = await PackagePurchase.create({
    user: req.user._id,
    package: pkg._id,
    packageName: pkg.name,
    amount: pkg.price,
    currency: 'EGP',
    paymentMethod: 'Demo Online Card',
    method: 'demo_online_card',
    status: 'success',
    transactionRef: transactionId,
    transactionId,
    cardLast4: String(cardLast4),
    startsAt,
    endsAt,
  });

  await logActivity({
    actor: req.user.name,
    actorRole: req.user.role,
    action: 'Demo subscription payment completed',
    target: pkg.name,
    details: `${pkg.name} activated using demo online card payment.`,
  });
  await createNotification({
    userId: req.user._id,
    title: 'Subscription activated',
    body: `${pkg.name} is now active on your account.`,
    type: 'promo',
    data: { transactionId, method: 'demo_online_card' },
  });

  res.status(201).json({
    success: true,
    message: 'Demo online subscription payment completed successfully',
    transactionId,
    subscription: mapPurchase(await purchase.populate('package')),
  });
});

export const createPackagePurchase = asyncHandler(async (req, res) => {
  const { packageId, paymentMethod, paymentIntentId } = req.body;

  const pkg = await ServicePackage.findById(packageId);
  if (!pkg) {
    return res.status(404).json({ success: false, message: 'Package not found' });
  }

  let verifiedIntent = null;
  if (process.env.PAYMENT_PROVIDER === 'stripe') {
    if (!stripeReady()) {
      return res.status(503).json({
        success: false,
        message: 'Stripe payments are not fully configured on this server',
      });
    }
    if (!paymentIntentId) {
      return res.status(400).json({
        success: false,
        message: 'paymentIntentId is required for Stripe payments',
      });
    }
    verifiedIntent = await getPaymentIntent(paymentIntentId);
    if (!verifiedIntent || verifiedIntent.status !== 'succeeded') {
      return res.status(409).json({
        success: false,
        message: 'Stripe payment has not succeeded yet',
      });
    }
  }

  const purchase = await PackagePurchase.create({
    user: req.user._id,
    package: pkg._id,
    packageName: pkg.name,
    amount: pkg.price,
    paymentMethod,
    status: 'paid',
    transactionRef: verifiedIntent?.id ?? `txn_${Date.now()}`,
    startsAt: new Date(),
    endsAt: new Date(Date.now() + pkg.durationMonths * 30 * 24 * 60 * 60 * 1000),
  });

  await logActivity({
    actor: req.user.name,
    actorRole: req.user.role,
    action: 'Package purchased',
    target: pkg.name,
    details: `${pkg.name} purchased using ${paymentMethod}.`,
  });
  await createNotification({
    userId: req.user._id,
    title: 'Package activated',
    body: `${pkg.name} is now active on your account.`,
    type: 'promo',
  });

  res.status(201).json({
    success: true,
    data: mapPurchase(await purchase.populate('package')),
  });
});

export const createPackagePaymentIntent = asyncHandler(async (req, res) => {
  const { packageId } = req.body;
  const pkg = await ServicePackage.findById(packageId);
  if (!pkg) {
    return res.status(404).json({ success: false, message: 'Package not found' });
  }

  if (process.env.PAYMENT_PROVIDER === 'stripe' && !stripeReady()) {
    return res.status(503).json({
      success: false,
      message: 'Stripe payments are not fully configured on this server',
    });
  }

  const intent = await createPaymentIntent({
    amount: pkg.price,
    currency: process.env.STRIPE_CURRENCY || 'usd',
    metadata: { packageId: pkg._id.toString(), userId: req.user._id.toString() },
  });
  if (!intent) {
    return res.status(501).json({
      success: false,
      message: 'Stripe is not configured on this server',
    });
  }
  res.status(201).json({
    success: true,
    data: {
      paymentIntentId: intent.id,
      clientSecret: intent.client_secret,
      amount: intent.amount,
      currency: intent.currency,
    },
  });
});

export const getPaymentConfig = asyncHandler(async (_req, res) => {
  const provider = process.env.PAYMENT_PROVIDER || 'simulated';
  res.status(200).json({
    success: true,
    data: {
      provider,
      currency: process.env.STRIPE_CURRENCY || 'usd',
      stripeReady: provider === 'stripe' && stripeReady(),
      stripePublishableKey:
        provider === 'stripe' && stripeReady() ? stripePublishableKey() : '',
      simulated: provider !== 'stripe',
    },
  });
});

export const getPackagePurchases = asyncHandler(async (req, res) => {
  const purchases = await PackagePurchase.find({ user: req.user._id })
    .populate('package')
    .sort({ createdAt: -1 });

  res.status(200).json({
    success: true,
    data: purchases.map(mapPurchase),
  });
});
