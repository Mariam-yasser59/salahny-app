import Booking from '../models/Booking.js';
import PackagePurchase from '../models/PackagePurchase.js';
import ServicePackage from '../models/Package.js';
import Service from '../models/Service.js';
import User from '../models/User.js';
import Workshop from '../models/Workshop.js';
import ActivityLog from '../models/ActivityLog.js';
import asyncHandler from '../utils/asyncHandler.js';
import { logActivity } from '../utils/activityLogger.js';
import { ensureAdminUser } from '../utils/ensureAdminUser.js';

const mapAccountStatus = (value) => {
  switch (value) {
    case 'pending':
      return 'Pending';
    case 'suspended':
      return 'Suspended';
    case 'rejected':
      return 'Rejected';
    case 'deleted':
      return 'Deleted';
    default:
      return 'Active';
  }
};

const mapBookingStatus = (value) => {
  switch (value) {
    case 'accepted':
      return 'Active';
    case 'completed':
      return 'Completed';
    case 'cancelled':
    case 'rejected':
      return 'Cancelled';
    default:
      return 'Pending';
  }
};

const mapDriver = async (user) => {
  const totalBookings = await Booking.countDocuments({ user: user._id });
  return {
    id: user._id.toString(),
    name: user.name,
    email: user.email,
    phone: user.phone,
    status: mapAccountStatus(user.accountStatus),
    totalBookings,
    walletBalance: totalBookings * 17,
    joinedAt: user.createdAt,
  };
};

const mapWorkshop = async (workshop) => {
  const totalJobs = await Booking.countDocuments({ workshop: workshop._id });
  const revenueAgg = await Booking.aggregate([
    { $match: { workshop: workshop._id } },
    { $group: { _id: null, total: { $sum: '$total' } } },
  ]);
  return {
    id: workshop._id.toString(),
    name: workshop.name,
    email: workshop.owner?.email ?? '',
    phone: workshop.owner?.phone ?? '',
    address: workshop.location,
    specialty: workshop.services?.[0] || 'Full Service',
    rating: workshop.rating ?? 4.8,
    totalJobs,
    revenue: revenueAgg[0]?.total ?? 0,
    isVerified: workshop.isVerified === true,
    status: mapAccountStatus(workshop.accountStatus),
    joinedAt: workshop.createdAt,
  };
};

const mapAdminBooking = (booking) => ({
  id: booking._id.toString(),
  driverId: booking.user?._id?.toString() ?? '',
  driverName: booking.user?.name ?? 'Unknown Driver',
  workshopId: booking.workshop?._id?.toString() ?? '',
  workshopName: booking.workshop?.name ?? 'Unknown Workshop',
  serviceId: booking.serviceId || booking.service,
  serviceName: booking.service,
  status: mapBookingStatus(booking.status),
  date: booking.date,
  time: booking.date,
  total: booking.total || 0,
  paymentMethod: booking.paymentMethod || 'Cash on Service',
});

const mapService = (service) => ({
  id: service._id.toString(),
  name: service.name,
  category: service.category,
  description: service.description,
  emoji: service.emoji,
  price: service.price,
  durationMins: service.durationMins,
  isPopular: service.isPopular,
  isEnabled: service.isEnabled !== false,
});

const mapPackage = (pkg) => ({
  id: pkg._id.toString(),
  name: pkg.name,
  tagline: pkg.tagline,
  duration: pkg.durationMonths === 1 ? 'month' : `${pkg.durationMonths} months`,
  price: pkg.price,
  originalPrice: pkg.originalPrice,
  features: pkg.features,
  isPopular: pkg.isPopular,
  isEnabled: pkg.isEnabled !== false,
});

const seedAdminData = async () => {
  await ensureAdminUser();

  const users = await User.find({ role: { $in: ['driver', 'workshop'] } }).limit(1);
  if (users.length > 0) {
    return;
  }

  const driver = await User.create({
    name: 'James Carter',
    email: 'james@example.com',
    phone: '01011112222',
    password: 'Driver123',
    role: 'driver',
    accountStatus: 'active',
  });
  const pendingDriver = await User.create({
    name: 'Sara Ahmed',
    email: 'sara.ahmed@example.com',
    phone: '01022223333',
    password: 'Driver123',
    role: 'driver',
    accountStatus: 'pending',
  });
  const workshopOwner = await User.create({
    name: 'Workshop Owner',
    email: 'owner@protech.com',
    phone: '01050001111',
    password: 'Workshop123',
    role: 'workshop',
    accountStatus: 'active',
  });
  const pendingWorkshopOwner = await User.create({
    name: 'QuickFix Owner',
    email: 'admin@quickfix.com',
    phone: '01050003333',
    password: 'Workshop123',
    role: 'workshop',
    accountStatus: 'pending',
  });

  const workshop = await Workshop.create({
    name: 'ProTech Auto Center',
    location: '142 Maple Ave, Downtown',
    services: ['Oil Change', 'Brake Service'],
    prices: { 'Oil Change': 89, 'Brake Service': 199 },
    owner: workshopOwner._id,
    rating: 4.9,
    isVerified: true,
    accountStatus: 'active',
  });

  await Workshop.create({
    name: 'QuickFix Motors',
    location: '33 Pine Rd, West District',
    services: ['Diagnostics & Electrical'],
    prices: { 'Diagnostics & Electrical': 149 },
    owner: pendingWorkshopOwner._id,
    rating: 4.6,
    isVerified: false,
    accountStatus: 'pending',
  });

  await Booking.create({
    user: driver._id,
    workshop: workshop._id,
    service: 'Oil Change',
    serviceId: 'svc_oil_change',
    status: 'accepted',
    date: new Date(Date.now() + 86400000),
    paymentMethod: 'Credit / Debit Card',
    total: 89,
    vehicleLabel: 'Toyota Camry 2022',
  });

  await Booking.create({
    user: pendingDriver._id,
    workshop: workshop._id,
    service: 'Brake Service',
    serviceId: 'svc_brake_service',
    status: 'pending',
    date: new Date(Date.now() + 172800000),
    paymentMethod: 'Cash on Service',
    total: 199,
    vehicleLabel: 'Hyundai Elantra 2021',
  });
};

export const getAdminSnapshot = asyncHandler(async (_req, res) => {
  await seedAdminData();

  const [drivers, workshops, bookings, services, packages, logs, purchases] =
    await Promise.all([
      User.find({ role: 'driver' }).sort({ createdAt: -1 }),
      Workshop.find().populate('owner', 'name email phone').sort({ createdAt: -1 }),
      Booking.find()
        .populate('user', 'name email phone')
        .populate('workshop', 'name location owner')
        .sort({ createdAt: -1 }),
      Service.find().sort({ createdAt: 1 }),
      ServicePackage.find().sort({ createdAt: 1 }),
      ActivityLog.find().sort({ createdAt: -1 }).limit(50),
      PackagePurchase.aggregate([{ $group: { _id: null, total: { $sum: '$amount' } } }]),
    ]);

  const driverItems = await Promise.all(drivers.map(mapDriver));
  const workshopItems = await Promise.all(workshops.map(mapWorkshop));
  const bookingItems = bookings.map(mapAdminBooking);
  const serviceItems = services.map(mapService);
  const packageItems = packages.map(mapPackage);
  const revenue =
    bookings.reduce((sum, item) => sum + (item.total || 0), 0) +
    (purchases[0]?.total ?? 0);

  res.status(200).json({
    success: true,
    data: {
      stats: {
        totalDrivers: driverItems.length,
        totalWorkshops: workshopItems.length,
        totalBookings: bookingItems.length,
        totalRevenue: revenue,
        pendingApprovals:
          driverItems.filter((item) => item.status === 'Pending').length +
          workshopItems.filter((item) => item.status === 'Pending').length,
        activeServices: serviceItems.filter((item) => item.isEnabled).length,
      },
      drivers: driverItems,
      workshops: workshopItems,
      bookings: bookingItems,
      services: serviceItems,
      packages: packageItems,
      logs: logs.map((log) => ({
        id: log._id.toString(),
        timestamp: log.createdAt,
        actor: log.actor,
        action: log.action,
        target: log.target,
        details: log.details,
      })),
    },
  });
});

export const getAdminUsers = asyncHandler(async (req, res) => {
  await seedAdminData();
  const role = req.query.role === 'workshop' ? 'workshop' : 'driver';

  if (role === 'driver') {
    const drivers = await User.find({ role: 'driver' }).sort({ createdAt: -1 });
    const items = await Promise.all(drivers.map(mapDriver));
    return res.status(200).json({ success: true, data: items });
  }

  const workshops = await Workshop.find()
    .populate('owner', 'name email phone')
    .sort({ createdAt: -1 });
  const items = await Promise.all(workshops.map(mapWorkshop));
  return res.status(200).json({ success: true, data: items });
});

export const updateAdminUserStatus = asyncHandler(async (req, res) => {
  const { status } = req.body;
  const user = await User.findById(req.params.id);

  if (!user) {
    return res.status(404).json({ success: false, message: 'User not found' });
  }

  user.accountStatus = status;
  await user.save();
  await logActivity({
    actor: req.user.name,
    actorRole: req.user.role,
    action: 'User status changed',
    target: user.name,
    details: `${user.role} account moved to ${status}.`,
  });

  res.status(200).json({ success: true, message: 'User updated' });
});

export const deleteAdminUser = asyncHandler(async (req, res) => {
  const user = await User.findById(req.params.id);

  if (!user) {
    return res.status(404).json({ success: false, message: 'User not found' });
  }

  await logActivity({
    actor: req.user.name,
    actorRole: req.user.role,
    action: 'User deleted',
    target: user.name,
    details: `${user.role} account removed by admin.`,
  });
  await user.deleteOne();
  res.status(200).json({ success: true, message: 'User deleted' });
});

export const getAdminBookings = asyncHandler(async (_req, res) => {
  const bookings = await Booking.find()
    .populate('user', 'name email phone')
    .populate('workshop', 'name location owner')
    .sort({ createdAt: -1 });

  res.status(200).json({
    success: true,
    data: bookings.map(mapAdminBooking),
  });
});

export const updateAdminBookingStatus = asyncHandler(async (req, res) => {
  const { status } = req.body;
  const map = {
    Pending: 'pending',
    Active: 'accepted',
    Completed: 'completed',
    Cancelled: 'cancelled',
    pending: 'pending',
    accepted: 'accepted',
    completed: 'completed',
    cancelled: 'cancelled',
  };
  const booking = await Booking.findById(req.params.id)
    .populate('user', 'name')
    .populate('workshop', 'name');

  if (!booking) {
    return res.status(404).json({ success: false, message: 'Booking not found' });
  }

  booking.status = map[status] || 'pending';
  await booking.save();
  await logActivity({
    actor: req.user.name,
    actorRole: req.user.role,
    action: 'Booking updated',
    target: booking._id.toString(),
    details: `Booking status changed to ${booking.status}.`,
  });

  res.status(200).json({
    success: true,
    data: mapAdminBooking(booking),
  });
});

export const getAdminLogs = asyncHandler(async (_req, res) => {
  const logs = await ActivityLog.find().sort({ createdAt: -1 }).limit(100);
  res.status(200).json({
    success: true,
    data: logs.map((log) => ({
      id: log._id.toString(),
      timestamp: log.createdAt,
      actor: log.actor,
      action: log.action,
      target: log.target,
      details: log.details,
    })),
  });
});
