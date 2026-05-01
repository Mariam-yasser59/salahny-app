import Booking from '../models/Booking.js';
import Workshop from '../models/Workshop.js';
import asyncHandler from '../utils/asyncHandler.js';

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
  } = req.body;

  if (!workshop || !service || !date) {
    return res.status(400).json({
      success: false,
      message: 'Workshop, service, and date are required',
    });
  }

  const workshopExists = await Workshop.findById(workshop);

  if (!workshopExists) {
    return res.status(404).json({
      success: false,
      message: 'Workshop not found',
    });
  }

  const booking = await Booking.create({
    user: req.user.role === 'admin' && user ? user : req.user._id,
    workshop,
    service,
    serviceId,
    date,
    paymentMethod,
    total,
    vehicleLabel,
  });

  const populatedBooking = await booking.populate([
    { path: 'user', select: 'name email role' },
    { path: 'workshop', select: 'name location services prices owner' },
  ]);

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

  res.status(200).json({
    success: true,
    count: bookings.length,
    data: bookings,
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

  res.status(200).json({
    success: true,
    data: booking,
  });
});

export const updateBookingStatus = asyncHandler(async (req, res) => {
  const { status } = req.body;
  const allowedStatuses = ['pending', 'accepted', 'rejected', 'completed', 'cancelled'];

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

  booking.status = status;
  await booking.save();

  const populatedBooking = await booking.populate([
    { path: 'user', select: 'name email role' },
    { path: 'workshop', select: 'name location owner' },
  ]);

  res.status(200).json({
    success: true,
    message: 'Booking status updated successfully',
    data: populatedBooking,
  });
});
