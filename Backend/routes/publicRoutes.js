import express from 'express';

import Booking from '../models/Booking.js';
import Service from '../models/Service.js';
import ServicePackage from '../models/Package.js';
import Workshop from '../models/Workshop.js';
import { egyptServiceCatalog } from '../data/egyptServiceCatalog.js';
import asyncHandler from '../utils/asyncHandler.js';

const router = express.Router();

const safeWorkshopProjection = {
  name: 1,
  location: 1,
  latitude: 1,
  longitude: 1,
  services: 1,
  serviceDetails: 1,
  workingHours: 1,
  availability: 1,
  availableSlots: 1,
  images: 1,
  rating: 1,
  reviewCount: 1,
  isVerified: 1,
};

const cleanServiceName = (value) => {
  if (!value) return '';
  if (typeof value === 'string') {
    return value === '[object Object]' ? '' : value.trim();
  }
  if (typeof value === 'object') {
    return cleanServiceName(value.name || value.title || value.label);
  }
  return String(value).trim();
};

const haversineKm = (lat1, lon1, lat2, lon2) => {
  const toRad = (value) => (value * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return 6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
};

const numberOrNull = (value) => {
  const n = Number(value);
  return Number.isFinite(n) ? n : null;
};

const mapPublicWorkshop = (workshop) => {
  const raw = workshop.toObject();
  const serviceDetails = (raw.serviceDetails || [])
    .map((service) => ({
      ...service,
      name: cleanServiceName(service),
      price: Number(service?.price) || 0,
      durationMins: Number(service?.durationMins) || 60,
      emoji: service?.emoji || 'Service',
    }))
    .filter((service) => service.name);
  const services = [
    ...serviceDetails.map((service) => service.name),
    ...(raw.services || []).map(cleanServiceName),
  ].filter(Boolean);
  const viewerLat = numberOrNull(workshop.$locals?.viewerLatitude);
  const viewerLon = numberOrNull(workshop.$locals?.viewerLongitude);
  const workshopLat = numberOrNull(raw.latitude);
  const workshopLon = numberOrNull(raw.longitude);
  const distanceKm =
    viewerLat !== null &&
    viewerLon !== null &&
    workshopLat !== null &&
    workshopLon !== null
      ? Number(haversineKm(viewerLat, viewerLon, workshopLat, workshopLon).toFixed(2))
      : null;
  return {
    ...raw,
    services: [...new Set(services)],
    serviceDetails,
    availableSlots: (raw.availableSlots || [])
      .map((slot) => new Date(slot))
      .filter((slot) => !Number.isNaN(slot.getTime()) && slot.getTime() > Date.now())
      .sort((a, b) => a - b),
    distanceKm,
    reviewCount: Number(raw.reviewCount) || 0,
    jobsDone: Number(workshop.$locals?.jobsDone) || 0,
  };
};

const completedCountsByWorkshop = async (workshopIds) => {
  const counts = await Booking.aggregate([
    { $match: { workshop: { $in: workshopIds }, status: 'completed' } },
    { $group: { _id: '$workshop', count: { $sum: 1 } } },
  ]);
  return new Map(counts.map((item) => [item._id.toString(), item.count]));
};

const sendPublicWorkshops = async (req, res) => {
  const viewerLatitude = numberOrNull(req.query.latitude);
  const viewerLongitude = numberOrNull(req.query.longitude);
  const search = req.query.search?.toString().trim();
  const searchRegex = search ? new RegExp(search.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i') : null;
  const filter = {
    accountStatus: 'active',
    isVerified: true,
  };
  if (searchRegex) {
    filter.$or = [
      { name: searchRegex },
      { location: searchRegex },
      { services: searchRegex },
      { 'serviceDetails.name': searchRegex },
    ];
  }
  const workshops = await Workshop.find({
    ...filter,
  }).select(safeWorkshopProjection);
  const completedCounts = await completedCountsByWorkshop(
    workshops.map((workshop) => workshop._id),
  );
  workshops.forEach((workshop) => {
    workshop.$locals.viewerLatitude = viewerLatitude;
    workshop.$locals.viewerLongitude = viewerLongitude;
    workshop.$locals.jobsDone = completedCounts.get(workshop._id.toString()) || 0;
  });
  const data = workshops
    .map(mapPublicWorkshop)
    .sort((a, b) => {
      if (a.distanceKm === null && b.distanceKm === null) return 0;
      if (a.distanceKm === null) return 1;
      if (b.distanceKm === null) return -1;
      return a.distanceKm - b.distanceKm;
    });
  res.status(200).json({
    success: true,
    count: workshops.length,
    data,
  });
};

router.get('/workshops', asyncHandler(sendPublicWorkshops));
router.get('/workshops/nearby', asyncHandler(sendPublicWorkshops));

router.get(
  '/workshops/:id',
  asyncHandler(async (req, res) => {
    const workshop = await Workshop.findOne({
      _id: req.params.id,
      accountStatus: 'active',
      isVerified: true,
    }).select(safeWorkshopProjection);
    if (!workshop) {
      return res.status(404).json({ success: false, message: 'Workshop not found' });
    }
    const completedCounts = await completedCountsByWorkshop([workshop._id]);
    workshop.$locals.jobsDone = completedCounts.get(workshop._id.toString()) || 0;
    res.status(200).json({ success: true, data: mapPublicWorkshop(workshop) });
  }),
);

router.get(
  '/services',
  asyncHandler(async (_req, res) => {
    const customServices = await Service.find({ isEnabled: { $ne: false } });
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
    res.status(200).json({ success: true, count: services.length, data: services });
  }),
);

router.get(
  '/packages',
  asyncHandler(async (_req, res) => {
    const packages = await ServicePackage.find({ isEnabled: { $ne: false } });
    res.status(200).json({ success: true, count: packages.length, data: packages });
  }),
);

export default router;
