import PackagePurchase from '../models/PackagePurchase.js';
import ServicePackage from '../models/Package.js';
import asyncHandler from '../utils/asyncHandler.js';
import { logActivity } from '../utils/activityLogger.js';
import { createNotification } from './notificationController.js';

const mapPurchase = (purchase) => ({
  id: purchase._id.toString(),
  packageId: purchase.package?._id?.toString() ?? purchase.package?.toString() ?? '',
  packageName: purchase.packageName,
  amount: purchase.amount,
  paymentMethod: purchase.paymentMethod,
  status: purchase.status,
  transactionRef: purchase.transactionRef,
  createdAt: purchase.createdAt,
});

export const createPackagePurchase = asyncHandler(async (req, res) => {
  const { packageId, paymentMethod } = req.body;

  const pkg = await ServicePackage.findById(packageId);
  if (!pkg) {
    return res.status(404).json({ success: false, message: 'Package not found' });
  }

  const purchase = await PackagePurchase.create({
    user: req.user._id,
    package: pkg._id,
    packageName: pkg.name,
    amount: pkg.price,
    paymentMethod,
    status: 'paid',
    transactionRef: `txn_${Date.now()}`,
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

export const getPackagePurchases = asyncHandler(async (req, res) => {
  const purchases = await PackagePurchase.find({ user: req.user._id })
    .populate('package')
    .sort({ createdAt: -1 });

  res.status(200).json({
    success: true,
    data: purchases.map(mapPurchase),
  });
});
