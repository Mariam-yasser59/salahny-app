import Booking from '../models/Booking.js';
import Workshop from '../models/Workshop.js';
import asyncHandler from '../utils/asyncHandler.js';
import { logActivity } from '../utils/activityLogger.js';
import { createNotification } from './notificationController.js';

const toPortalStatus = (status) => {
  switch (status) {
    case 'accepted':
      return 'accepted';
    case 'completed':
      return 'completed';
    case 'cancelled':
      return 'cancelled';
    default:
      return 'pending';
  }
};

const mapPortalBooking = (booking) => ({
  id: booking._id.toString(),
  serviceName: booking.service,
  customerName: booking.user?.name ?? 'Unknown Driver',
  customerPhone: booking.user?.phone ?? '',
  vehicleInfo: booking.vehicleLabel || 'Vehicle details unavailable',
  date: booking.date,
  time: booking.date,
  status: toPortalStatus(booking.status),
  price: booking.total || 0,
  progress:
    booking.status === 'completed'
      ? 1
      : booking.status === 'accepted'
        ? 0.45
        : 0.05,
});

export const getWorkshopPortalDashboard = asyncHandler(async (req, res) => {
  const workshop = await Workshop.findOne({ owner: req.user._id });

  if (!workshop) {
    return res.status(404).json({
      success: false,
      message: 'No workshop profile found for this account',
    });
  }

  const bookings = await Booking.find({ workshop: workshop._id })
    .populate('user', 'name phone')
    .sort({ createdAt: -1 });

  const revenue = bookings.reduce((sum, item) => sum + (item.total || 0), 0);

  res.status(200).json({
    success: true,
    data: {
      profile: {
        id: workshop._id.toString(),
        name: workshop.name,
        initials: workshop.name
          .split(' ')
          .filter(Boolean)
          .slice(0, 2)
          .map((part) => part[0])
          .join(),
        specialty: workshop.services?.[0] || 'Full Service',
        rating: workshop.rating ?? 4.8,
        isOpen: workshop.accountStatus === 'active',
        isVerified: workshop.isVerified === true,
        monthlyRevenue: revenue,
        revenuePeriod: 'Current period',
        payoutMethod: 'Bank Transfer',
      },
      bookings: bookings.map(mapPortalBooking),
      stats: {
        jobsToday: bookings.length,
        pending: bookings.filter((item) => item.status === 'pending').length,
        revenue,
      },
    },
  });
});

export const getWorkshopPortalBookings = asyncHandler(async (req, res) => {
  const workshop = await Workshop.findOne({ owner: req.user._id });

  if (!workshop) {
    return res.status(404).json({
      success: false,
      message: 'No workshop profile found for this account',
    });
  }

  const bookings = await Booking.find({ workshop: workshop._id })
    .populate('user', 'name phone')
    .sort({ createdAt: -1 });

  res.status(200).json({
    success: true,
    data: bookings.map(mapPortalBooking),
  });
});

export const updateWorkshopPortalBookingStatus = asyncHandler(async (req, res) => {
  const workshop = await Workshop.findOne({ owner: req.user._id });
  const booking = await Booking.findById(req.params.id).populate('user', 'name');

  if (!workshop || !booking || booking.workshop.toString() !== workshop._id.toString()) {
    return res.status(404).json({
      success: false,
      message: 'Booking not found for this workshop',
    });
  }

  const map = {
    accepted: 'accepted',
    completed: 'completed',
    cancelled: 'cancelled',
    rejected: 'rejected',
    pending: 'pending',
  };
  booking.status = map[req.body.status] || 'pending';
  await booking.save();

  await logActivity({
    actor: workshop.name,
    actorRole: 'workshop',
    action: 'Workshop booking updated',
    target: booking._id.toString(),
    details: `Booking for ${booking.user?.name ?? 'driver'} moved to ${booking.status}.`,
  });
  await createNotification({
    userId: booking.user,
    title: 'Workshop updated your booking',
    body: `${workshop.name} marked your ${booking.service} booking as ${booking.status}.`,
    type: 'booking',
  });

  res.status(200).json({
    success: true,
    data: mapPortalBooking(booking),
  });
});
