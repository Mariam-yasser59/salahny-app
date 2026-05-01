import ServicePackage from '../models/Package.js';
import Service from '../models/Service.js';
import asyncHandler from '../utils/asyncHandler.js';
import { logActivity } from '../utils/activityLogger.js';

const defaultServices = [
  {
    name: 'Oil Change',
    category: 'Maintenance',
    description: 'Full synthetic oil change with filter replacement',
    emoji: '🔧',
    price: 89,
    durationMins: 45,
    isPopular: true,
  },
  {
    name: 'Tire Rotation',
    category: 'Tires',
    description: 'Rotate and balance all four tires',
    emoji: '🔁',
    price: 59,
    durationMins: 60,
  },
  {
    name: 'Brake Service',
    category: 'Brakes',
    description: 'Brake pad inspection and replacement',
    emoji: '🛑',
    price: 199,
    durationMins: 90,
    isPopular: true,
  },
  {
    name: 'Battery Check',
    category: 'Electrical',
    description: 'Battery test and terminal cleaning',
    emoji: '🔋',
    price: 39,
    durationMins: 30,
  },
];

const defaultPackages = [
  {
    name: 'Basic',
    tagline: 'Perfect for 1 vehicle',
    durationMonths: 1,
    price: 29,
    originalPrice: 49,
    features: [
      'Monthly checkup',
      '10% service discount',
      'WhatsApp support',
      '2 emergency calls',
    ],
  },
  {
    name: 'Premium',
    tagline: 'Best for families',
    durationMonths: 3,
    price: 79,
    originalPrice: 129,
    isPopular: true,
    features: [
      'Weekly checkup',
      '25% discount',
      '24/7 priority support',
      '5 emergency calls',
      'Free monthly wash',
      'Full diagnostic report',
    ],
  },
  {
    name: 'Fleet',
    tagline: 'For businesses & fleets',
    durationMonths: 12,
    price: 599,
    originalPrice: 899,
    features: [
      'Daily monitoring',
      '40% discount',
      'Dedicated manager',
      'Unlimited emergency',
      'Self-service bay',
      'Custom reports',
      'API integration',
    ],
  },
];

const ensureCatalogSeed = async () => {
  const [serviceCount, packageCount] = await Promise.all([
    Service.countDocuments(),
    ServicePackage.countDocuments(),
  ]);

  if (serviceCount === 0) {
    await Service.insertMany(defaultServices);
  }

  if (packageCount === 0) {
    await ServicePackage.insertMany(defaultPackages);
  }
};

export const getServices = asyncHandler(async (_req, res) => {
  await ensureCatalogSeed();
  const services = await Service.find().sort({ createdAt: 1 });

  res.status(200).json({
    success: true,
    count: services.length,
    data: services,
  });
});

export const getPackages = asyncHandler(async (_req, res) => {
  await ensureCatalogSeed();
  const packages = await ServicePackage.find().sort({ createdAt: 1 });

  res.status(200).json({
    success: true,
    count: packages.length,
    data: packages,
  });
});

export const createService = asyncHandler(async (req, res) => {
  const service = await Service.create(req.body);
  await logActivity({
    actor: req.user.name,
    actorRole: req.user.role,
    action: 'Service created',
    target: service.name,
    details: `Service created at \$${service.price}.`,
  });
  res.status(201).json({ success: true, data: service });
});

export const updateService = asyncHandler(async (req, res) => {
  const service = await Service.findByIdAndUpdate(req.params.id, req.body, {
    new: true,
    runValidators: true,
  });
  if (!service) {
    return res.status(404).json({ success: false, message: 'Service not found' });
  }
  await logActivity({
    actor: req.user.name,
    actorRole: req.user.role,
    action: 'Service updated',
    target: service.name,
    details: 'Service configuration updated.',
  });
  res.status(200).json({ success: true, data: service });
});

export const deleteService = asyncHandler(async (req, res) => {
  const service = await Service.findById(req.params.id);
  if (!service) {
    return res.status(404).json({ success: false, message: 'Service not found' });
  }
  await service.deleteOne();
  await logActivity({
    actor: req.user.name,
    actorRole: req.user.role,
    action: 'Service deleted',
    target: service.name,
    details: 'Service removed from catalog.',
  });
  res.status(200).json({ success: true, message: 'Service deleted' });
});

export const createPackage = asyncHandler(async (req, res) => {
  const pkg = await ServicePackage.create(req.body);
  await logActivity({
    actor: req.user.name,
    actorRole: req.user.role,
    action: 'Package created',
    target: pkg.name,
    details: `Package created at \$${pkg.price}.`,
  });
  res.status(201).json({ success: true, data: pkg });
});

export const updatePackage = asyncHandler(async (req, res) => {
  const pkg = await ServicePackage.findByIdAndUpdate(req.params.id, req.body, {
    new: true,
    runValidators: true,
  });
  if (!pkg) {
    return res.status(404).json({ success: false, message: 'Package not found' });
  }
  await logActivity({
    actor: req.user.name,
    actorRole: req.user.role,
    action: 'Package updated',
    target: pkg.name,
    details: 'Package configuration updated.',
  });
  res.status(200).json({ success: true, data: pkg });
});

export const deletePackage = asyncHandler(async (req, res) => {
  const pkg = await ServicePackage.findById(req.params.id);
  if (!pkg) {
    return res.status(404).json({ success: false, message: 'Package not found' });
  }
  await pkg.deleteOne();
  await logActivity({
    actor: req.user.name,
    actorRole: req.user.role,
    action: 'Package deleted',
    target: pkg.name,
    details: 'Package removed from catalog.',
  });
  res.status(200).json({ success: true, message: 'Package deleted' });
});
