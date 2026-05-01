const Booking = require('../models/Booking');
const Workshop = require('../models/Workshop');

const PROGRESS = {
  pending: 0,
  accepted: 20,
  rejected: 0,
  in_progress: 40,
  diagnostics_ready: 60,
  repair_in_progress: 80,
  completed: 100,
  cancelled: 0,
};

const getBookings = async (req, res) => {
  try {
    let query = {};

    if (req.user.role === 'driver') {
      query = { $or: [{ user: req.user._id }, { driverId: req.user._id.toString() }] };
    } else if (req.user.role === 'workshop') {
      const workshops = await Workshop.find({ owner: req.user._id }).select('_id');
      const workshopIds = workshops.map((workshop) => workshop._id);
      query = { $or: [{ workshop: { $in: workshopIds } }, { workshopId: req.user._id.toString() }] };
    }

    if (req.query.status) query.status = req.query.status;

    const bookings = await Booking.find(query)
      .populate('user', 'name email phone role')
      .populate('workshop')
      .sort({ createdAt: -1 });

    return res.json(bookings);
  } catch (err) {
    return res.status(500).json({ detail: err.message });
  }
};

const createBooking = async (req, res) => {
  try {
    if (req.user.role !== 'driver') {
      return res.status(403).json({ detail: 'Only drivers can create bookings' });
    }

    const workshopId = req.body.workshop || req.body.workshopId;
    const workshop = await Workshop.findById(workshopId);
    if (!workshop) {
      return res.status(404).json({ detail: 'Workshop not found' });
    }

    const service = req.body.service || req.body.serviceName;
    const booking = await Booking.create({
      user: req.user._id,
      workshop: workshop._id,
      service,
      date: req.body.date || new Date(),
      driverId: req.user._id.toString(),
      driverName: req.user.name,
      driverPhone: req.user.phone || '',
      workshopId: workshop.owner.toString(),
      workshopName: workshop.name,
      vehicleId: req.body.vehicleId,
      vehicleInfo: req.body.vehicleInfo,
      serviceName: service,
      time: req.body.time,
      notes: req.body.notes,
      price: req.body.price || 0,
    });

    return res.status(201).json(booking);
  } catch (err) {
    return res.status(500).json({ detail: err.message });
  }
};

const getBookingById = async (req, res) => {
  try {
    const booking = await Booking.findById(req.params.id).populate('user', 'name email phone role').populate('workshop');
    if (!booking) {
      return res.status(404).json({ detail: 'Booking not found' });
    }

    const uid = req.user._id.toString();
    const workshop = booking.workshop;
    const bookingUserId = booking.user?._id?.toString() || booking.user?.toString();
    const isDriver = bookingUserId === uid || booking.driverId === uid;
    const isWorkshopOwner = workshop?.owner?.toString() === uid || booking.workshopId === uid;

    if (!isDriver && !isWorkshopOwner && req.user.role !== 'admin') {
      return res.status(403).json({ detail: 'Access denied' });
    }

    return res.json(booking);
  } catch {
    return res.status(400).json({ detail: 'Invalid booking ID' });
  }
};

const updateBookingStatus = async (req, res) => {
  try {
    const { status, notes } = req.body;
    if (!Object.keys(PROGRESS).includes(status)) {
      return res.status(400).json({ detail: `Invalid status. Valid: ${Object.keys(PROGRESS).join(', ')}` });
    }

    const booking = await Booking.findById(req.params.id).populate('workshop');
    if (!booking) {
      return res.status(404).json({ detail: 'Booking not found' });
    }

    const uid = req.user._id.toString();
    const isDriver = booking.user?.toString() === uid || booking.driverId === uid;
    const isWorkshopOwner = booking.workshop?.owner?.toString() === uid || booking.workshopId === uid;

    if (!isDriver && !isWorkshopOwner && req.user.role !== 'admin') {
      return res.status(403).json({ detail: 'Access denied' });
    }

    booking.status = status;
    booking.progress = PROGRESS[status];
    if (notes) booking.statusNotes = notes;
    await booking.save();

    return res.json(booking);
  } catch (err) {
    return res.status(500).json({ detail: err.message });
  }
};

module.exports = {
  getBookings,
  createBooking,
  getBookingById,
  updateBookingStatus,
};
