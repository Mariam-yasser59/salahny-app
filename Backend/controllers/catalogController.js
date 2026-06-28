import ServicePackage from '../models/Package.js';
import Service from '../models/Service.js';
import { egyptServiceCatalog } from '../data/egyptServiceCatalog.js';
import asyncHandler from '../utils/asyncHandler.js';
import { logActivity } from '../utils/activityLogger.js';

export const getServices = asyncHandler(async (_req, res) => {
  const customServices = await Service.find().sort({ createdAt: 1 });
  const customByName = new Map(customServices.map((item) => [item.name.toLowerCase(), item.toObject()]));
  const services = egyptServiceCatalog.map((item) => ({
    ...item,
    ...(customByName.get(item.name.toLowerCase()) || {}),
    id: item.id,
    name: item.name,
    category: item.category,
    price: item.price,
    isEnabled: true,
  }));

  res.status(200).json({
    success: true,
    count: services.length,
    data: services,
  });
});

export const getPackages = asyncHandler(async (_req, res) => {
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
