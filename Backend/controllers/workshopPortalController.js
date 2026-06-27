import Booking from '../models/Booking.js';
import Workshop from '../models/Workshop.js';
import AdminWorkshopMessage from '../models/AdminWorkshopMessage.js';
import User from '../models/User.js';
import Earning from '../models/Earning.js';
import asyncHandler from '../utils/asyncHandler.js';
import { logActivity } from '../utils/activityLogger.js';
import { createNotification } from './notificationController.js';
import { emitWorkshopAdminMessage } from '../services/realtimeService.js';
import { createBookingEarning } from './bookingController.js';
import Diagnostic from '../models/Diagnostic.js';
import Review from '../models/Review.js';
import { sendEmail } from '../services/emailService.js';

const toPortalStatus = (status) => {
  switch (status) {
    case 'accepted':
      return 'accepted';
    case 'in_progress':
      return 'in_progress';
    case 'diagnostics_ready':
      return 'diagnostics_ready';
    case 'repair_in_progress':
      return 'repair_in_progress';
    case 'completed':
      return 'completed';
    case 'cancelled':
      return 'cancelled';
    case 'rejected':
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
  driverReviewed: booking.reviewState?.driverReviewed === true,
  workshopReviewed: booking.reviewState?.workshopReviewed === true,
  driverRating: booking.reviewState?.driverRating ?? null,
  workshopRating: booking.reviewState?.workshopRating ?? null,
  progress:
    booking.status === 'completed'
      ? 1
      : booking.status === 'accepted'
        ? 0.45
        : 0.05,
});

const addReviewState = async (bookings) => {
  const ids = bookings.map((booking) => booking._id);
  const reviews = await Review.find({ booking: { $in: ids } }).select(
    'booking reviewerRole rating',
  );
  const byBooking = new Map();
  reviews.forEach((review) => {
    const key = review.booking.toString();
    const state = byBooking.get(key) || {
      driverReviewed: false,
      workshopReviewed: false,
      driverRating: null,
      workshopRating: null,
    };
    if (review.reviewerRole === 'driver') {
      state.driverReviewed = true;
      state.driverRating = review.rating;
    }
    if (review.reviewerRole === 'workshop') {
      state.workshopReviewed = true;
      state.workshopRating = review.rating;
    }
    byBooking.set(key, state);
  });
  bookings.forEach((booking) => {
    booking.reviewState = byBooking.get(booking._id.toString()) || {
      driverReviewed: false,
      workshopReviewed: false,
      driverRating: null,
      workshopRating: null,
    };
  });
  return bookings;
};

const mapPortalService = (service) => ({
  id: service._id?.toString() || service.id || service.name,
  name: service.name,
  price: service.price || 0,
  durationMins: service.durationMins || 60,
  emoji: service.emoji || 'Service',
});

const mapAdminMessage = (message, currentUserId) => ({
  id: message._id.toString(),
  workshopId: message.workshop?._id?.toString?.() ?? message.workshop?.toString() ?? '',
  text: message.text,
  senderId: message.sender?._id?.toString?.() ?? message.sender?.toString() ?? '',
  senderRole: message.senderRole,
  senderName: message.sender?.name ?? (message.senderRole === 'admin' ? 'Admin' : 'Workshop'),
  time: message.createdAt,
  isMe:
    (message.sender?._id?.toString?.() ?? message.sender?.toString()) ===
    currentUserId,
  readByAdmin: message.readByAdmin,
  readByWorkshop: message.readByWorkshop,
});

const currentServiceDetails = (workshop) => {
  if (workshop.serviceDetails?.length) {
    return workshop.serviceDetails.map(mapPortalService);
  }

  if (workshop.customServices?.length) {
    return workshop.customServices.map(mapPortalService);
  }

  return workshop.services.map((name) => ({
    id: name,
    name,
    price: workshop.prices?.get(name) ?? 0,
    durationMins: 60,
    emoji: 'Service',
  }));
};

const syncServiceIndexes = (workshop) => {
  workshop.services = workshop.serviceDetails.map((service) => service.name);
  workshop.prices = new Map(
    workshop.serviceDetails.map((service) => [service.name, service.price || 0]),
  );
};

const serializeSlot = (slot) => new Date(slot).toISOString();

const parseFutureSlots = (rawSlots) => {
  const rejected = [];
  const accepted = [];
  for (const rawSlot of rawSlots) {
    if (typeof rawSlot !== 'string') {
      rejected.push({ slot: rawSlot, reason: 'slot must be an ISO string' });
      continue;
    }
    const hasTimezone = /(?:z|[+-]\d{2}:\d{2})$/i.test(rawSlot);
    if (!hasTimezone) {
      rejected.push({ slot: rawSlot, reason: 'slot must include UTC timezone offset' });
      continue;
    }
    const slot = new Date(rawSlot);
    if (Number.isNaN(slot.getTime())) {
      rejected.push({ slot: rawSlot, reason: 'invalid date' });
      continue;
    }
    if (slot.getTime() <= Date.now()) {
      rejected.push({ slot: rawSlot, reason: 'slot must be in the future' });
      continue;
    }
    accepted.push(slot);
  }
  const uniqueSlots = [
    ...new Map(accepted.map((slot) => [slot.toISOString(), slot])).values(),
  ].sort((a, b) => a - b);
  return { slots: uniqueSlots, rejected };
};

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
  await addReviewState(bookings);

  const earned = await Earning.aggregate([
    { $match: { workshop: workshop._id } },
    { $group: { _id: null, total: { $sum: '$amount' } } },
  ]);
  const totalEarnings = earned[0]?.total ?? 0;
  const activeStatuses = [
    'accepted',
    'in_progress',
    'diagnostics_ready',
    'repair_in_progress',
  ];

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
        specialty: currentServiceDetails(workshop)[0]?.name || 'Full Service',
        rating: workshop.rating ?? 4.8,
        isOpen: workshop.accountStatus === 'active',
        isVerified: workshop.isVerified === true,
        accountStatus: workshop.accountStatus,
        address: workshop.location || '',
        latitude: workshop.latitude,
        longitude: workshop.longitude,
        monthlyRevenue: totalEarnings,
        revenuePeriod: 'Current period',
        payoutMethod: 'Bank Transfer',
        completedServices: bookings.filter((item) => item.status === 'completed').length,
        reviewCount: workshop.reviewCount || 0,
      },
      bookings: bookings.map(mapPortalBooking),
      stats: {
        jobsToday: bookings.length,
        totalBookings: bookings.length,
        pending: bookings.filter((item) => item.status === 'pending').length,
        active: bookings.filter((item) => activeStatuses.includes(item.status)).length,
        completed: bookings.filter((item) => item.status === 'completed').length,
        rejected: bookings.filter((item) => item.status === 'rejected').length,
        cancelled: bookings.filter((item) => item.status === 'cancelled').length,
        revenue: totalEarnings,
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
  await addReviewState(bookings);

  res.status(200).json({
    success: true,
    data: bookings.map(mapPortalBooking),
  });
});

export const getWorkshopPortalServices = asyncHandler(async (req, res) => {
  const workshop = await Workshop.findOne({ owner: req.user._id });

  if (!workshop) {
    return res.status(404).json({
      success: false,
      message: 'No workshop profile found for this account',
    });
  }

  res.status(200).json({
    success: true,
    data: currentServiceDetails(workshop),
  });
});

export const updateWorkshopPortalServices = asyncHandler(async (req, res) => {
  const workshop = await Workshop.findOne({ owner: req.user._id });

  if (!workshop) {
    return res.status(404).json({
      success: false,
      message: 'No workshop profile found for this account',
    });
  }

  const services = (Array.isArray(req.body.services) ? req.body.services : [])
    .filter((service) => service?.name)
    .map((service) => ({
      name: service.name.toString(),
      price: Number(service.price) || 0,
      durationMins: Number(service.durationMins) || 60,
      emoji: service.emoji?.toString() || 'Service',
    }));
  workshop.serviceDetails = services;
  syncServiceIndexes(workshop);
  await workshop.save();

  await logActivity({
    actor: workshop.name,
    actorRole: 'workshop',
    action: 'Workshop services updated',
    target: workshop._id.toString(),
    details: `${workshop.services.length} services configured.`,
  });

  res.status(200).json({
    success: true,
    data: workshop.serviceDetails.map(mapPortalService),
  });
});

export const addWorkshopService = asyncHandler(async (req, res) => {
  const workshop = await Workshop.findOne({ owner: req.user._id });

  if (!workshop) {
    return res.status(404).json({
      success: false,
      message: 'No workshop profile found for this account',
    });
  }

  const { name, price = 0, durationMins = 60, emoji = 'Service' } = req.body;
  if (!name) {
    return res.status(400).json({
      success: false,
      message: 'Service name is required',
    });
  }

  if (!workshop.serviceDetails?.length && workshop.customServices?.length) {
    workshop.serviceDetails = workshop.customServices.map((service) => mapPortalService(service));
  }

  workshop.serviceDetails.push({
    name: name.toString(),
    price: Number(price) || 0,
    durationMins: Number(durationMins) || 60,
    emoji: emoji.toString(),
  });
  syncServiceIndexes(workshop);
  await workshop.save();

  const added = workshop.serviceDetails[workshop.serviceDetails.length - 1];
  res.status(201).json({ success: true, data: mapPortalService(added) });
});

export const deleteWorkshopService = asyncHandler(async (req, res) => {
  const workshop = await Workshop.findOne({ owner: req.user._id });

  if (!workshop) {
    return res.status(404).json({
      success: false,
      message: 'No workshop profile found for this account',
    });
  }

  const serviceId = req.params.serviceId;
  if (!workshop.serviceDetails?.length && workshop.customServices?.length) {
    workshop.serviceDetails = workshop.customServices.map((service) => mapPortalService(service));
  }
  workshop.serviceDetails = workshop.serviceDetails.filter(
    (service) => service._id?.toString() !== serviceId && service.id !== serviceId && service.name !== serviceId,
  );
  syncServiceIndexes(workshop);
  await workshop.save();

  res.status(200).json({ success: true, message: 'Service deleted' });
});

export const updateWorkshopPortalBookingStatus = asyncHandler(async (req, res) => {
  const workshop = await Workshop.findOne({ owner: req.user._id });
  const booking = await Booking.findById(req.params.id).populate('user', 'name email');

  if (!workshop || !booking || booking.workshop.toString() !== workshop._id.toString()) {
    return res.status(404).json({
      success: false,
      message: 'Booking not found for this workshop',
    });
  }

  const map = {
    accepted: 'accepted',
    in_progress: 'in_progress',
    diagnostics_ready: 'diagnostics_ready',
    repair_in_progress: 'repair_in_progress',
    completed: 'completed',
    cancelled: 'cancelled',
    rejected: 'rejected',
    pending: 'pending',
  };
  const nextStatus = map[req.body.status] || 'pending';
  if (['diagnostics_ready', 'repair_in_progress', 'completed'].includes(nextStatus)) {
    const hasBookingDiagnostic = await Diagnostic.exists({ booking: booking._id });
    if (!hasBookingDiagnostic) {
      return res.status(409).json({
        success: false,
        message:
          'Run or attach a workshop diagnostic before moving this booking beyond in-progress',
      });
    }
  }
  booking.status = nextStatus;
  await booking.save();
  await createBookingEarning(booking);

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
    data: { bookingId: booking._id.toString(), status: booking.status },
  });
  if (['accepted', 'rejected', 'completed'].includes(booking.status)) {
    const emailByStatus = {
      accepted: {
        subject: 'Your service request was accepted',
        body: 'Your service request has been accepted by the workshop.',
      },
      rejected: {
        subject: 'Your service request was rejected',
        body: 'Your service request has been rejected by the workshop.',
      },
      completed: {
        subject: 'Your service has been completed',
        body: 'Your service has been completed.',
      },
    };
    const emailCopy = emailByStatus[booking.status];
    await sendEmail({
      to: booking.user?.email,
      subject: emailCopy.subject,
      text: `Hello ${booking.user?.name || 'Driver'},\n\n${emailCopy.body}\n\nWorkshop: ${workshop.name}\nService: ${booking.service}\n\nOpen Salahny to view the latest details.`,
      html: `<p>Hello ${booking.user?.name || 'Driver'},</p><p>${emailCopy.body}</p><p>Workshop: ${workshop.name}<br/>Service: ${booking.service}</p><p>Open Salahny to view the latest details.</p>`,
    });
  }

  res.status(200).json({
    success: true,
    data: mapPortalBooking((await addReviewState([booking]))[0]),
  });
});

export const getWorkshopEarnings = asyncHandler(async (req, res) => {
  const workshop = await Workshop.findOne({ owner: req.user._id });
  if (!workshop) {
    return res.status(404).json({ success: false, message: 'No workshop profile found for this account' });
  }
  const earnings = await Earning.find({ workshop: workshop._id })
    .populate('booking', 'service date total')
    .populate('driver', 'name')
    .sort({ createdAt: -1 });
  const total = earnings.reduce((sum, item) => sum + item.amount, 0);
  res.status(200).json({
    success: true,
    data: {
      total,
      availableBalance: earnings.filter((item) => item.status !== 'paid').reduce((sum, item) => sum + item.amount, 0),
      paid: earnings.filter((item) => item.status === 'paid').reduce((sum, item) => sum + item.amount, 0),
      items: earnings.map((item) => ({
        id: item._id.toString(),
        bookingId: item.booking?._id?.toString() ?? '',
        driverName: item.driver?.name ?? '',
        serviceName: item.booking?.service ?? '',
        amount: item.amount,
        status: item.status,
        createdAt: item.createdAt,
      })),
    },
  });
});

export const getWorkshopPortalSlots = asyncHandler(async (req, res) => {
  const workshop = await Workshop.findOne({ owner: req.user._id });
  if (!workshop) {
    return res.status(404).json({
      success: false,
      message: 'No workshop profile found for this account',
    });
  }
  res.status(200).json({
    success: true,
    data: workshop.availableSlots
      .filter((slot) => slot.getTime() > Date.now())
      .sort((a, b) => a - b)
      .map(serializeSlot),
  });
});

export const updateWorkshopPortalSlots = asyncHandler(async (req, res) => {
  const workshop = await Workshop.findOne({ owner: req.user._id });
  if (!workshop) {
    return res.status(404).json({
      success: false,
      message: 'No workshop profile found for this account',
    });
  }
  if (!Array.isArray(req.body.slots)) {
    return res.status(400).json({
      success: false,
      message: 'slots must be an array of ISO date strings',
    });
  }
  const { slots, rejected } = parseFutureSlots(req.body.slots);
  console.info('[workshop-slots] update requested', {
    workshopId: workshop._id.toString(),
    ownerId: req.user._id.toString(),
    requested: req.body.slots.length,
    accepted: slots.length,
    rejected: rejected.length,
  });
  if (rejected.length > 0) {
    return res.status(400).json({
      success: false,
      message: 'All slots must be future ISO date strings with timezone offsets',
      errors: rejected.slice(0, 5),
    });
  }
  workshop.availableSlots = slots;
  await workshop.save();
  res.status(200).json({
    success: true,
    data: workshop.availableSlots.map(serializeSlot),
  });
});

export const getWorkshopAdminMessages = asyncHandler(async (req, res) => {
  const workshop = await Workshop.findOne({ owner: req.user._id });
  if (!workshop) {
    return res.status(404).json({
      success: false,
      message: 'No workshop profile found for this account',
    });
  }

  const messages = await AdminWorkshopMessage.find({ workshop: workshop._id })
    .populate('sender', 'name role')
    .sort({ createdAt: 1 });

  await AdminWorkshopMessage.updateMany(
    { workshop: workshop._id, senderRole: 'admin', readByWorkshop: false },
    { readByWorkshop: true },
  );

  res.status(200).json({
    success: true,
    data: {
      workshop: {
        id: workshop._id.toString(),
        name: workshop.name,
      },
      messages: messages.map((message) =>
        mapAdminMessage(message, req.user._id.toString()),
      ),
    },
  });
});

export const sendWorkshopAdminMessage = asyncHandler(async (req, res) => {
  const { text } = req.body;
  if (!text || !text.trim()) {
    return res.status(400).json({ success: false, message: 'Message text is required' });
  }

  const workshop = await Workshop.findOne({ owner: req.user._id });
  if (!workshop) {
    return res.status(404).json({
      success: false,
      message: 'No workshop profile found for this account',
    });
  }

  const message = await AdminWorkshopMessage.create({
    workshop: workshop._id,
    sender: req.user._id,
    senderRole: 'workshop',
    text: text.trim(),
    readByAdmin: false,
    readByWorkshop: true,
  });

  const populated = await message.populate('sender', 'name role');
  const admins = await User.find({ role: 'admin', accountStatus: { $ne: 'deleted' } }).select('_id');
  await Promise.all(
    admins.map((admin) =>
      createNotification({
        userId: admin._id,
        title: 'Workshop message',
        body: `${workshop.name}: ${text.trim()}`,
        type: 'chat',
      }),
    ),
  );
  await logActivity({
    actor: workshop.name,
    actorRole: 'workshop',
    action: 'Workshop messaged admin',
    target: workshop._id.toString(),
    details: text.trim(),
  });
  emitWorkshopAdminMessage(workshop._id, mapAdminMessage(populated, ''));

  res.status(201).json({
    success: true,
    data: mapAdminMessage(populated, req.user._id.toString()),
  });
});
