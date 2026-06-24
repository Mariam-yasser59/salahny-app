import Booking from '../models/Booking.js';
import TrackingUpdate from '../models/TrackingUpdate.js';
import Workshop from '../models/Workshop.js';
import asyncHandler from '../utils/asyncHandler.js';
import { emitTrackingUpdate } from '../services/realtimeService.js';

const ensureAccess = async (bookingId, user) => {
  const booking = await Booking.findById(bookingId).populate('workshop', 'owner');
  if (!booking) return null;
  const allowed =
    user.role === 'admin' ||
    booking.user.toString() === user._id.toString() ||
    booking.workshop?.owner?.toString() === user._id.toString();
  return allowed ? booking : false;
};

const mapUpdate = (item) => ({
  id: item._id.toString(),
  bookingId: item.booking.toString(),
  latitude: item.latitude,
  longitude: item.longitude,
  etaMinutes: item.etaMinutes,
  note: item.note,
  time: item.createdAt,
});

export const getTrackingUpdates = asyncHandler(async (req, res) => {
  const booking = await ensureAccess(req.params.bookingId, req.user);
  if (booking === null) return res.status(404).json({ success: false, message: 'Booking not found' });
  if (booking === false) return res.status(403).json({ success: false, message: 'Access denied' });
  const updates = await TrackingUpdate.find({ booking: booking._id }).sort({ createdAt: -1 }).limit(50);
  res.status(200).json({ success: true, data: updates.map(mapUpdate) });
});

export const addTrackingUpdate = asyncHandler(async (req, res) => {
  const booking = await Booking.findById(req.params.bookingId).populate('workshop', 'owner');
  if (!booking) return res.status(404).json({ success: false, message: 'Booking not found' });
  const canUpdate =
    req.user.role === 'admin' ||
    booking.workshop?.owner?.toString() === req.user._id.toString();
  if (!canUpdate) return res.status(403).json({ success: false, message: 'Access denied' });
  const { latitude, longitude, etaMinutes = 0, note = '' } = req.body;
  if (Number.isNaN(Number(latitude)) || Number.isNaN(Number(longitude))) {
    return res.status(400).json({ success: false, message: 'latitude and longitude are required' });
  }
  const update = await TrackingUpdate.create({
    booking: booking._id,
    latitude,
    longitude,
    etaMinutes,
    note,
    updatedBy: req.user._id,
  });
  const payload = mapUpdate(update);
  emitTrackingUpdate(booking._id.toString(), payload);
  res.status(201).json({ success: true, data: payload });
});
