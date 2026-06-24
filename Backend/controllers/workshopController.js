import User from '../models/User.js';
import Workshop from '../models/Workshop.js';
import VerificationDocument from '../models/VerificationDocument.js';
import asyncHandler from '../utils/asyncHandler.js';
import { deleteWorkshopRelatedData } from '../utils/cascadeDelete.js';
import { createNotification } from './notificationController.js';
import { sendAccountStatusEmail } from '../services/emailService.js';

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
  if (value === undefined || value === null || value === '') return null;
  const n = Number(value);
  return Number.isFinite(n) ? n : null;
};

const hasCoordinateValue = (value) =>
  value !== undefined && value !== null && value !== '';

const parseCoordinatePair = (latitude, longitude) => {
  const lat = numberOrNull(latitude);
  const lon = numberOrNull(longitude);
  if (
    hasCoordinateValue(latitude) !== hasCoordinateValue(longitude) ||
    (hasCoordinateValue(latitude) && (lat === null || lon === null))
  ) {
    return { ok: false };
  }
  return { ok: true, latitude: lat, longitude: lon };
};

export const createWorkshop = asyncHandler(async (req, res) => {
  const {
    name,
    location,
    services = [],
    prices = {},
    serviceDetails,
    workingHours = '',
    availability = 'open',
    images = [],
    owner,
    rating = 4.8,
    isVerified = false,
    accountStatus = 'pending',
    availableSlots = [],
    latitude = null,
    longitude = null,
    phone = '',
    supportsEmergencyService = true,
  } = req.body;

  if (!name || !location) {
    return res.status(400).json({
      success: false,
      message: 'Name and location are required',
    });
  }
  const coordinates = parseCoordinatePair(latitude, longitude);
  if (!coordinates.ok) {
    return res.status(400).json({
      success: false,
      message: 'latitude and longitude must be valid numbers when provided',
    });
  }

  const ownerId = req.user.role === 'admin' && owner ? owner : req.user._id;
  const ownerUser = await User.findById(ownerId);

  if (!ownerUser) {
    return res.status(404).json({
      success: false,
      message: 'Owner user not found',
    });
  }

  const normalizedServiceDetails = normalizeServiceDetails({
    serviceDetails,
    services,
    prices,
  });

  if (req.user.role === 'workshop') {
    const existingWorkshop = await Workshop.findOne({ owner: ownerUser._id });
    if (existingWorkshop) {
      return res.status(409).json({
        success: false,
        message: 'This account already owns a workshop profile',
      });
    }
  }

  const workshop = await Workshop.create({
    name,
    location,
    services: normalizedServiceDetails.map((service) => service.name),
    prices: priceMapFromDetails(normalizedServiceDetails),
    serviceDetails: normalizedServiceDetails,
    workingHours,
    availability,
    images,
    owner: ownerUser._id,
    rating,
    isVerified,
    accountStatus,
    availableSlots,
    latitude: coordinates.latitude,
    longitude: coordinates.longitude,
    phone,
    supportsEmergencyService,
  });

  const populatedWorkshop = await workshop.populate(
    'owner',
    'name email phone role',
  );

  res.status(201).json({
    success: true,
    message: 'Workshop created successfully',
    data: populatedWorkshop,
  });
});

export const getWorkshops = asyncHandler(async (req, res) => {
  const filter =
    req.user?.role === 'admin'
      ? {}
      : { accountStatus: 'active', isVerified: true };
  const workshops = await Workshop.find(filter).populate(
    'owner',
    'name email phone role',
  );

  res.status(200).json({
    success: true,
    count: workshops.length,
    data: workshops,
  });
});

export const getNearbyWorkshops = asyncHandler(async (req, res) => {
  const latitude = numberOrNull(req.query.latitude);
  const longitude = numberOrNull(req.query.longitude);
  if (latitude === null || longitude === null) {
    return res.status(400).json({
      success: false,
      message: 'latitude and longitude query parameters are required',
    });
  }
  const workshops = await Workshop.find({
    accountStatus: 'active',
    isVerified: true,
    latitude: { $ne: null },
    longitude: { $ne: null },
  }).populate('owner', 'name email phone role');
  const data = workshops
    .map((workshop) => {
      const raw = workshop.toObject();
      return {
        ...raw,
        distanceKm: Number(
          haversineKm(latitude, longitude, workshop.latitude, workshop.longitude).toFixed(2),
        ),
      };
    })
    .sort((a, b) => a.distanceKm - b.distanceKm);
  res.status(200).json({ success: true, count: data.length, data });
});

export const getWorkshopById = asyncHandler(async (req, res) => {
  const workshop = await Workshop.findById(req.params.id).populate(
    'owner',
    'name email phone role',
  );

  if (!workshop) {
    return res.status(404).json({
      success: false,
      message: 'Workshop not found',
    });
  }

  const canViewHidden =
    req.user?.role === 'admin' ||
    workshop.owner?._id?.toString?.() === req.user?._id?.toString();
  if (
    !canViewHidden &&
    (workshop.accountStatus !== 'active' || workshop.isVerified !== true)
  ) {
    return res.status(404).json({
      success: false,
      message: 'Workshop not found',
    });
  }

  res.status(200).json({
    success: true,
    data: workshop,
  });
});

export const updateWorkshop = asyncHandler(async (req, res) => {
  const workshop = await Workshop.findById(req.params.id);

  if (!workshop) {
    return res.status(404).json({
      success: false,
      message: 'Workshop not found',
    });
  }

  const canManage =
    req.user.role === 'admin' || workshop.owner.toString() === req.user._id.toString();

  if (!canManage) {
    return res.status(403).json({
      success: false,
      message: 'You cannot update this workshop',
    });
  }

  const {
    name,
    location,
    services,
    prices,
    serviceDetails,
    workingHours,
    availability,
    images,
    rating,
    isVerified,
    accountStatus,
    availableSlots,
    latitude,
    longitude,
    phone,
    supportsEmergencyService,
  } = req.body;

  if (name !== undefined) workshop.name = name;
  if (location !== undefined) {
    if (!location.toString().trim()) {
      return res.status(400).json({ success: false, message: 'Location address cannot be empty' });
    }
    workshop.location = location.toString().trim();
  }
  if (serviceDetails !== undefined || services !== undefined || prices !== undefined) {
    const normalizedServiceDetails = normalizeServiceDetails({
      serviceDetails: serviceDetails ?? workshop.serviceDetails,
      services: services ?? workshop.services,
      prices: prices ?? workshop.prices,
    });
    workshop.services = normalizedServiceDetails.map((service) => service.name);
    workshop.prices = priceMapFromDetails(normalizedServiceDetails);
    workshop.serviceDetails = normalizedServiceDetails;
  }
  if (workingHours !== undefined) workshop.workingHours = workingHours;
  if (availability !== undefined) workshop.availability = availability;
  if (images !== undefined) workshop.images = images;
  if (rating !== undefined) workshop.rating = rating;
  if (
    req.user.role === 'admin' &&
    accountStatus === 'active' &&
    isVerified === true
  ) {
    const approvedDocument = await VerificationDocument.exists({
      workshop: workshop._id,
      status: 'approved',
    });
    if (!approvedDocument) {
      return res.status(409).json({
        success: false,
        message: 'Review and approve a workshop document before activating this workshop',
      });
    }
  }
  if (isVerified !== undefined) workshop.isVerified = isVerified;
  if (accountStatus !== undefined) workshop.accountStatus = accountStatus;
  if (availableSlots !== undefined) workshop.availableSlots = availableSlots;
  if (latitude !== undefined || longitude !== undefined) {
    const coordinates = parseCoordinatePair(latitude, longitude);
    if (!coordinates.ok) {
      return res.status(400).json({
        success: false,
        message: 'latitude and longitude must be valid numbers when provided',
      });
    }
    workshop.latitude = coordinates.latitude;
    workshop.longitude = coordinates.longitude;
  }
  if (phone !== undefined) workshop.phone = phone;
  if (supportsEmergencyService !== undefined) {
    workshop.supportsEmergencyService = supportsEmergencyService;
  }

  await workshop.save();

  if (req.user.role === 'admin') {
    const ownerUpdate = {};
    if (workshop.accountStatus === 'active' && workshop.isVerified === true) {
      ownerUpdate.accountStatus = 'active';
      ownerUpdate.verificationStatus = 'admin_approved';
    } else if (workshop.accountStatus === 'rejected') {
      ownerUpdate.accountStatus = 'rejected';
      ownerUpdate.verificationStatus = 'admin_rejected';
    }
    if (Object.keys(ownerUpdate).length > 0) {
      const ownerUser = await User.findByIdAndUpdate(workshop.owner, ownerUpdate, {
        new: true,
      });
      if (ownerUser) {
        const approved = ownerUpdate.accountStatus === 'active';
        await createNotification({
          userId: ownerUser._id,
          title: approved ? 'Workshop account approved' : 'Workshop account rejected',
          body: approved
            ? 'Your Salahny workshop account has been approved. You can now log in.'
            : 'Your workshop verification was rejected. Please check admin notes or contact support.',
          type: 'system',
          data: { workshopId: workshop._id.toString(), accountStatus: ownerUpdate.accountStatus },
        });
        await sendAccountStatusEmail({
          user: ownerUser,
          status: approved ? 'active' : 'rejected',
        });
      }
    }
  }

  const populatedWorkshop = await workshop.populate(
    'owner',
    'name email phone role',
  );

  res.status(200).json({
    success: true,
    message: 'Workshop updated successfully',
    data: populatedWorkshop,
  });
});

export const deleteWorkshop = asyncHandler(async (req, res) => {
  const workshop = await Workshop.findById(req.params.id);

  if (!workshop) {
    return res.status(404).json({
      success: false,
      message: 'Workshop not found',
    });
  }

  const canManage =
    req.user.role === 'admin' || workshop.owner.toString() === req.user._id.toString();

  if (!canManage) {
    return res.status(403).json({
      success: false,
      message: 'You cannot delete this workshop',
    });
  }

  await deleteWorkshopRelatedData(workshop._id, workshop.owner);

  res.status(200).json({
    success: true,
    message: 'Workshop deleted successfully',
  });
});

const normalizeServiceDetails = ({ serviceDetails, services, prices }) => {
  if (Array.isArray(serviceDetails) && serviceDetails.length > 0) {
    return serviceDetails
      .filter((service) => service?.name)
      .map((service) => ({
        name: service.name.toString(),
        price: Number(service.price) || 0,
        durationMins: Number(service.durationMins) || 60,
        emoji: service.emoji?.toString() || 'Service',
      }));
  }

  const priceLookup =
    prices instanceof Map ? prices : new Map(Object.entries(prices || {}));

  return (Array.isArray(services) ? services : [])
    .filter(Boolean)
    .map((name) => ({
      name: name.toString(),
      price: Number(priceLookup.get(name.toString())) || 0,
      durationMins: 60,
      emoji: 'Service',
    }));
};

const priceMapFromDetails = (services) =>
  new Map(services.map((service) => [service.name, Number(service.price) || 0]));
