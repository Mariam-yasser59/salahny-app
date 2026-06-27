import Booking from '../models/Booking.js';
import Workshop from '../models/Workshop.js';
import asyncHandler from '../utils/asyncHandler.js';
import { createNotification } from './notificationController.js';
import Earning from '../models/Earning.js';
import Diagnostic from '../models/Diagnostic.js';
import Review from '../models/Review.js';
import { sendEmail } from '../services/emailService.js';

const numberOrNull = (value) => {
  if (value === undefined || value === null || value === '') return null;
  const n = Number(value);
  return Number.isFinite(n) ? n : null;
};

const hasCoordinateValue = (value) =>
  value !== undefined && value !== null && value !== '';

const sendBookingEmail = async ({ to, subject, lines }) =>
  sendEmail({
    to,
    subject,
    text: lines.filter(Boolean).join('\n'),
    html: lines
      .filter(Boolean)
      .map((line) => `<p>${line}</p>`)
      .join(''),
  });

export const createBookingEarning = async (booking) => {
  if (booking.status !== 'completed') return null;
  return Earning.findOneAndUpdate(
    { booking: booking._id },
    {
      $setOnInsert: {
        workshop: booking.workshop._id ?? booking.workshop,
        booking: booking._id,
        driver: booking.user._id ?? booking.user,
        serviceId: booking.serviceId || booking.service,
        amount: booking.total || 0,
        status: 'earned',
      },
    },
    { upsert: true, new: true },
  );
};

const addReviewState = async (bookings) => {
  const list = Array.isArray(bookings) ? bookings : [bookings];
  const ids = list.map((booking) => booking._id);
  const reviews = await Review.find({ booking: { $in: ids } }).select(
    'booking reviewerRole rating comment',
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

  return list.map((booking) => {
    const raw = booking.toObject ? booking.toObject() : booking;
    const state = byBooking.get(booking._id.toString()) || {
      driverReviewed: false,
      workshopReviewed: false,
      driverRating: null,
      workshopRating: null,
    };
    return { ...raw, reviewState: state };
  });
};

export const createBooking = asyncHandler(async (req, res) => {
  const {
    workshop,
    service,
    serviceId = '',
    date,
    user,
    paymentMethod = 'Cash on Service',
    total = 0,
    vehicleLabel = '',
    vehicleId = '',
    address = '',
    latitude = null,
    longitude = null,
    locationNotes = '',
  } = req.body;

  if (!workshop || !service || !date) {
    return res.status(400).json({
      success: false,
      message: 'Workshop, service, and date are required',
    });
  }

  const normalizedAddress = address.toString().trim();
  if (!normalizedAddress) {
    return res.status(400).json({
      success: false,
      message: 'Pickup/service address is required',
    });
  }

  const normalizedLatitude = numberOrNull(latitude);
  const normalizedLongitude = numberOrNull(longitude);
  if (
    hasCoordinateValue(latitude) !== hasCoordinateValue(longitude) ||
    (hasCoordinateValue(latitude) && (normalizedLatitude === null || normalizedLongitude === null))
  ) {
    return res.status(400).json({
      success: false,
      message: 'latitude and longitude must be valid numbers when provided',
    });
  }

  const workshopExists = await Workshop.findById(workshop);

  if (!workshopExists) {
    return res.status(404).json({
      success: false,
      message: 'Workshop not found',
    });
  }

  if (
    workshopExists.accountStatus !== 'active' ||
    workshopExists.isVerified !== true
  ) {
    return res.status(403).json({
      success: false,
      message: 'This workshop is not approved for bookings',
    });
  }

  const bookingDate = new Date(date);
  if (Number.isNaN(bookingDate.getTime())) {
    return res.status(400).json({
      success: false,
      message: 'date must be a valid ISO date',
    });
  }

  const existingBooking = await Booking.findOne({
    workshop,
    date: bookingDate,
    status: { $nin: ['rejected', 'cancelled'] },
  });
  if (existingBooking) {
    return res.status(409).json({
      success: false,
      message: 'This time slot is already booked',
    });
  }

  const reservedWorkshop = await Workshop.findOneAndUpdate(
    {
      _id: workshop,
      accountStatus: 'active',
      isVerified: true,
      availableSlots: bookingDate,
    },
    { $pull: { availableSlots: bookingDate } },
    { new: true },
  );

  if (!reservedWorkshop) {
    return res.status(409).json({
      success: false,
      message: 'This slot is no longer available.',
    });
  }

  const booking = await Booking.create({
    user: req.user.role === 'admin' && user ? user : req.user._id,
    workshop,
    service,
    serviceId,
    date: bookingDate,
    paymentMethod,
    total,
    vehicleLabel,
    vehicleId,
    address: normalizedAddress,
    latitude: normalizedLatitude,
    longitude: normalizedLongitude,
    locationNotes: locationNotes.toString().trim(),
  });

  const populatedBooking = await booking.populate([
    { path: 'user', select: 'name email phone role' },
    {
      path: 'workshop',
      select: 'name location services prices owner phone',
      populate: { path: 'owner', select: 'name email phone' },
    },
  ]);
  await createNotification({
    userId: populatedBooking.user._id,
    title: 'Booking created',
    body: `${service} was booked with ${populatedBooking.workshop.name}.`,
    type: 'booking',
    data: { bookingId: booking._id.toString(), workshopId: workshop.toString() },
  });
  if (populatedBooking.workshop?.owner?._id) {
    await createNotification({
      userId: populatedBooking.workshop.owner._id,
      title: 'New service request',
      body: `${populatedBooking.user.name} requested ${service}.`,
      type: 'booking',
      data: { bookingId: booking._id.toString(), driverId: populatedBooking.user._id.toString() },
    });
    await sendBookingEmail({
      to: populatedBooking.workshop.owner.email,
      subject: 'New service request',
      lines: [
        `Hello ${populatedBooking.workshop.owner.name || populatedBooking.workshop.name},`,
        'You have received a new service request in Salahny.',
        `Service: ${service}`,
        `Driver: ${populatedBooking.user.name}`,
        populatedBooking.address ? `Location: ${populatedBooking.address}` : '',
        'Please open Salahny Workshop Dashboard to review and respond.',
      ],
    });
  }

  res.status(201).json({
    success: true,
    message: 'Booking created successfully',
    data: populatedBooking,
  });
});

export const getBookings = asyncHandler(async (req, res) => {
  const filter = {};

  if (req.user.role === 'driver') {
    filter.user = req.user._id;
  }

  if (req.user.role === 'workshop') {
    const ownedWorkshops = await Workshop.find({ owner: req.user._id }).select('_id');
    filter.workshop = { $in: ownedWorkshops.map((item) => item._id) };
  }

  if (req.query.status) {
    filter.status = req.query.status;
  }

  const bookings = await Booking.find(filter)
    .populate('user', 'name email role')
    .populate('workshop', 'name location');
  const data = await addReviewState(bookings);

  res.status(200).json({
    success: true,
    count: bookings.length,
    data,
  });
});

export const getBookingById = asyncHandler(async (req, res) => {
  const booking = await Booking.findById(req.params.id)
    .populate('user', 'name email role')
    .populate('workshop', 'name location owner');

  if (!booking) {
    return res.status(404).json({
      success: false,
      message: 'Booking not found',
    });
  }

  const isOwner =
    req.user.role === 'admin' ||
    booking.user._id.toString() === req.user._id.toString() ||
    booking.workshop.owner?.toString() === req.user._id.toString();

  if (!isOwner) {
    return res.status(403).json({
      success: false,
      message: 'You cannot view this booking',
    });
  }

  const [data] = await addReviewState(booking);

  res.status(200).json({
    success: true,
    data,
  });
});

export const updateBookingStatus = asyncHandler(async (req, res) => {
  const { status } = req.body;
  const allowedStatuses = [
    'pending',
    'accepted',
    'in_progress',
    'diagnostics_ready',
    'repair_in_progress',
    'rejected',
    'completed',
    'cancelled',
  ];

  if (!allowedStatuses.includes(status)) {
    return res.status(400).json({
      success: false,
      message: 'Invalid booking status',
    });
  }

  const booking = await Booking.findById(req.params.id).populate(
    'workshop',
    'owner name',
  );

  if (!booking) {
    return res.status(404).json({
      success: false,
      message: 'Booking not found',
    });
  }

  const canUpdate =
    req.user.role === 'admin' ||
    booking.workshop.owner.toString() === req.user._id.toString();

  if (!canUpdate) {
    return res.status(403).json({
      success: false,
      message: 'You cannot update this booking status',
    });
  }

  if (['diagnostics_ready', 'repair_in_progress', 'completed'].includes(status)) {
    const hasBookingDiagnostic = await Diagnostic.exists({ booking: booking._id });
    if (!hasBookingDiagnostic) {
      return res.status(409).json({
        success: false,
        message:
          'A workshop diagnostic must be attached before moving this booking beyond in-progress',
      });
    }
  }

  booking.status = status;
  await booking.save();
  await createBookingEarning(booking);

  const populatedBooking = await booking.populate([
    { path: 'user', select: 'name email phone role' },
    { path: 'workshop', select: 'name location owner' },
  ]);
  await createNotification({
    userId: populatedBooking.user._id,
    title: 'Booking status updated',
    body: `${populatedBooking.service} is now ${booking.status}.`,
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
    await sendBookingEmail({
      to: populatedBooking.user.email,
      subject: emailCopy.subject,
      lines: [
        `Hello ${populatedBooking.user.name},`,
        emailCopy.body,
        `Workshop: ${populatedBooking.workshop.name}`,
        `Service: ${populatedBooking.service}`,
        'Open Salahny to view the latest booking details.',
      ],
    });
  }

  const [data] = await addReviewState(populatedBooking);

  res.status(200).json({
    success: true,
    message: 'Booking status updated successfully',
    data,
  });
});
