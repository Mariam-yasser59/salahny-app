import EmergencyRequest from '../models/EmergencyRequest.js';
import EmergencyMessage from '../models/EmergencyMessage.js';
import Workshop from '../models/Workshop.js';
import User from '../models/User.js';
import Vehicle from '../models/Vehicle.js';
import asyncHandler from '../utils/asyncHandler.js';
import { logActivity } from '../utils/activityLogger.js';
import { createNotification } from './notificationController.js';
import { sendEmail } from '../services/emailService.js';

const activeStatuses = [
  'assigned',
  'accepted_by_workshop',
  'mechanic_on_the_way',
  'arrived',
  'in_progress',
];
const workshopStatuses = [
  'accepted_by_workshop',
  'mechanic_on_the_way',
  'arrived',
  'in_progress',
  'completed',
];

const haversineKm = (lat1, lon1, lat2, lon2) => {
  const toRad = (value) => (value * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return 6371 * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
};

const hasCoordinateValue = (value) =>
  value !== undefined && value !== null && value !== '';

const numberOrNull = (value) => {
  if (!hasCoordinateValue(value)) return null;
  const n = Number(value);
  return Number.isFinite(n) ? n : null;
};

const populateRequest = (query) =>
  query
    .populate('user', 'name phone email')
    .populate('vehicle', 'make model year plate')
    .populate({
      path: 'assignedWorkshop',
      select: 'name location latitude longitude phone owner availability',
      populate: { path: 'owner', select: 'name phone email' },
    })
    .populate('assignedBy', 'name email');

const toPayload = (request) => ({
  emergencyRequestId: request._id.toString(),
  id: request._id.toString(),
  driver: request.user
    ? {
        id: request.user._id?.toString?.() ?? request.user.toString(),
        name: request.user.name,
        phone: request.user.phone,
        email: request.user.email,
      }
    : null,
  vehicle: request.vehicle
    ? {
        id: request.vehicle._id?.toString?.() ?? request.vehicle.toString(),
        make: request.vehicle.make,
        model: request.vehicle.model,
        year: request.vehicle.year,
        plate: request.vehicle.plate,
      }
    : null,
  emergencyType: request.emergencyType,
  issueDescription: request.issueDescription,
  address: request.address,
  latitude: request.latitude,
  longitude: request.longitude,
  locationNotes: request.locationNotes,
  phone: request.phone,
  vehicleLabel: request.vehicleLabel,
  assignedWorkshop: request.assignedWorkshop
    ? {
        id: request.assignedWorkshop._id?.toString?.() ?? request.assignedWorkshop.toString(),
        name: request.assignedWorkshop.name,
        phone: request.assignedWorkshop.phone || request.assignedWorkshop.owner?.phone || '',
        address: request.assignedWorkshop.location,
        distanceKm: request.distanceKm,
      }
    : null,
  assignedBy: request.assignedBy
    ? {
        id: request.assignedBy._id?.toString?.() ?? request.assignedBy.toString(),
        name: request.assignedBy.name,
      }
    : null,
  assignmentMethod: request.assignmentMethod,
  distanceKm: request.distanceKm,
  status: request.status,
  statusHistory: request.statusHistory,
  completedAt: request.completedAt,
  cancelledReason: request.cancelledReason,
  createdAt: request.createdAt,
  updatedAt: request.updatedAt,
});

const notifyAdmins = async (title, body) => {
  const admins = await User.find({ role: 'admin', accountStatus: { $ne: 'deleted' } }).select('_id');
  await Promise.all(admins.map((admin) => createNotification({ userId: admin._id, title, body, type: 'emergency' })));
};

const sendEmergencyEmail = async ({ to, subject, lines }) =>
  sendEmail({
    to,
    subject,
    text: lines.filter(Boolean).join('\n'),
    html: lines
      .filter(Boolean)
      .map((line) => `<p>${line}</p>`)
      .join(''),
  });

const addHistory = (request, status, userId, note = '') => {
  request.status = status;
  request.statusHistory.push({ status, changedBy: userId, note });
  if (status === 'completed') request.completedAt = new Date();
};

const findNearestWorkshop = async (latitude, longitude) => {
  if (!Number.isFinite(latitude) || !Number.isFinite(longitude)) return null;
  const workshops = await Workshop.find({
    accountStatus: 'active',
    isVerified: true,
    supportsEmergencyService: true,
    availability: { $ne: 'closed' },
    latitude: { $ne: null },
    longitude: { $ne: null },
  })
    .populate('owner', 'name phone email')
    .sort({ updatedAt: -1 });
  return workshops
    .map((workshop) => ({
      workshop,
      distanceKm: haversineKm(latitude, longitude, workshop.latitude, workshop.longitude),
    }))
    .sort((a, b) => {
      const distanceDelta = a.distanceKm - b.distanceKm;
      if (Math.abs(distanceDelta) > 0.05) return distanceDelta;
      if (a.workshop.availability !== b.workshop.availability) {
        return a.workshop.availability === 'open' ? -1 : 1;
      }
      const ratingDelta = (b.workshop.rating || 0) - (a.workshop.rating || 0);
      if (Math.abs(ratingDelta) > 0.01) return ratingDelta;
      return new Date(b.workshop.updatedAt).getTime() - new Date(a.workshop.updatedAt).getTime();
    })[0] ?? null;
};

export const createEmergencyRequest = asyncHandler(async (req, res) => {
  const {
    address,
    latitude,
    longitude,
    locationNotes = '',
    issueDescription,
    vehicleId,
    emergencyType = 'other',
    phone = '',
    vehicleLabel = '',
  } = req.body;
  if (!address || !issueDescription) {
    return res.status(400).json({ success: false, message: 'address and issueDescription are required' });
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
  if (vehicleId) {
    const vehicle = await Vehicle.findOne({ _id: vehicleId, owner: req.user._id });
    if (!vehicle) return res.status(404).json({ success: false, message: 'Vehicle not found' });
  }

  const nearest = await findNearestWorkshop(normalizedLatitude, normalizedLongitude);
  const request = await EmergencyRequest.create({
    user: req.user._id,
    vehicle: vehicleId || null,
    emergencyType,
    issueDescription,
    address,
    latitude: normalizedLatitude,
    longitude: normalizedLongitude,
    locationNotes,
    phone,
    vehicleLabel,
    assignedWorkshop: nearest?.workshop?._id ?? null,
    assignmentMethod: nearest ? 'ai_nearest_match' : 'unassigned',
    distanceKm: nearest ? Number(nearest.distanceKm.toFixed(2)) : null,
    status: nearest ? 'assigned' : 'pending_admin_assignment',
    statusHistory: [
      {
        status: nearest ? 'assigned' : 'pending_admin_assignment',
        changedBy: req.user._id,
        note: nearest ? 'Nearest approved workshop matched automatically' : 'No eligible workshop matched',
      },
    ],
  });

  await notifyAdmins('Emergency request created', `${req.user.name} requested ${emergencyType} assistance.`);
  if (nearest?.workshop?.owner) {
    await createNotification({
      userId: nearest.workshop.owner,
      title: 'Emergency request assigned',
      body: `${req.user.name} needs ${emergencyType} assistance nearby.`,
      type: 'emergency',
      data: { emergencyRequestId: request._id.toString() },
    });
    const owner = nearest.workshop.owner;
    await sendEmergencyEmail({
      to: owner.email,
      subject: 'New Salahny emergency request assigned',
      lines: [
        `Hello ${owner.name || nearest.workshop.name},`,
        `${req.user.name} needs ${emergencyType} assistance.`,
        `Address: ${address}`,
        locationNotes ? `Notes: ${locationNotes}` : '',
        'Open Salahny Workshop Dashboard to accept or update the request.',
      ],
    });
  }
  await logActivity({
    actor: req.user.name,
    actorRole: req.user.role,
    action: 'Emergency request created',
    target: emergencyType,
    details: address,
  });
  const populated = await populateRequest(EmergencyRequest.findById(request._id));
  res.status(201).json({ success: true, data: toPayload(populated) });
});

export const getMyEmergencyRequests = asyncHandler(async (req, res) => {
  const requests = await populateRequest(EmergencyRequest.find({ user: req.user._id }).sort({ createdAt: -1 }));
  res.status(200).json({ success: true, count: requests.length, data: requests.map(toPayload) });
});

export const getEmergencyById = asyncHandler(async (req, res) => {
  const request = await populateRequest(EmergencyRequest.findById(req.params.id));
  if (!request) return res.status(404).json({ success: false, message: 'Emergency request not found' });
  const ownsWorkshop = request.assignedWorkshop?.owner?._id?.toString() === req.user._id.toString();
  if (req.user.role !== 'admin' && request.user._id.toString() !== req.user._id.toString() && !ownsWorkshop) {
    return res.status(403).json({ success: false, message: 'Access denied' });
  }
  res.status(200).json({ success: true, data: toPayload(request) });
});

export const cancelEmergencyRequest = asyncHandler(async (req, res) => {
  const request = await EmergencyRequest.findById(req.params.id);
  if (!request) return res.status(404).json({ success: false, message: 'Emergency request not found' });
  if (request.user.toString() !== req.user._id.toString()) {
    return res.status(403).json({ success: false, message: 'Access denied' });
  }
  if (['completed', 'cancelled', 'rejected'].includes(request.status)) {
    return res.status(409).json({ success: false, message: 'This request can no longer be cancelled' });
  }
  request.cancelledReason = req.body.reason?.toString() || 'Cancelled by driver';
  addHistory(request, 'cancelled', req.user._id, request.cancelledReason);
  await request.save();
  await notifyAdmins('Emergency request cancelled', `${req.user.name} cancelled an emergency request.`);
  const populated = await populateRequest(EmergencyRequest.findById(request._id));
  res.status(200).json({ success: true, data: toPayload(populated) });
});

export const getWorkshopEmergencyRequests = asyncHandler(async (req, res) => {
  const workshop = await Workshop.findOne({ owner: req.user._id });
  if (!workshop) return res.status(404).json({ success: false, message: 'No workshop profile found' });
  const requests = await populateRequest(
    EmergencyRequest.find({ assignedWorkshop: workshop._id }).sort({ createdAt: -1 }),
  );
  res.status(200).json({ success: true, data: requests.map(toPayload) });
});

const updateWorkshopEmergency = async (req, res, status) => {
  const workshop = await Workshop.findOne({ owner: req.user._id });
  const request = await EmergencyRequest.findById(req.params.id);
  if (!workshop || !request || request.assignedWorkshop?.toString() !== workshop._id.toString()) {
    return res.status(404).json({ success: false, message: 'Emergency request not found for this workshop' });
  }
  addHistory(request, status, req.user._id);
  await request.save();
  await createNotification({
    userId: request.user,
    title: 'Emergency status updated',
    body: `${workshop.name} marked your request as ${status}.`,
    type: 'emergency',
    data: { emergencyRequestId: request._id.toString(), status },
  });
  if (['accepted_by_workshop', 'rejected', 'completed'].includes(status)) {
    const driver = await User.findById(request.user).select('name email');
    await sendEmergencyEmail({
      to: driver?.email,
      subject: `Your Salahny emergency request is ${status.replaceAll('_', ' ')}`,
      lines: [
        `Hello ${driver?.name || 'Driver'},`,
        `${workshop.name} marked your emergency request as ${status.replaceAll('_', ' ')}.`,
        'Open Salahny to view the latest emergency details.',
      ],
    });
  }
  await notifyAdmins('Emergency status updated', `${workshop.name} marked a request as ${status}.`);
  const populated = await populateRequest(EmergencyRequest.findById(request._id));
  res.status(200).json({ success: true, data: toPayload(populated) });
};

export const acceptEmergencyRequest = asyncHandler((req, res) =>
  updateWorkshopEmergency(req, res, 'accepted_by_workshop'),
);
export const rejectEmergencyRequest = asyncHandler((req, res) =>
  updateWorkshopEmergency(req, res, 'rejected'),
);
export const updateEmergencyStatus = asyncHandler(async (req, res) => {
  const { status } = req.body;
  if (!workshopStatuses.includes(status)) {
    return res.status(400).json({ success: false, message: 'Invalid workshop emergency status' });
  }
  return updateWorkshopEmergency(req, res, status);
});

export const getAdminEmergencyRequests = asyncHandler(async (_req, res) => {
  const requests = await populateRequest(EmergencyRequest.find().sort({ createdAt: -1 }));
  res.status(200).json({ success: true, data: requests.map(toPayload) });
});

export const assignEmergencyWorkshop = asyncHandler(async (req, res) => {
  const request = await EmergencyRequest.findById(req.params.id);
  const workshop = await Workshop.findOne({
    _id: req.body.workshopId,
    accountStatus: 'active',
    isVerified: true,
  });
  if (!request || !workshop) {
    return res.status(404).json({ success: false, message: 'Request or approved workshop not found' });
  }
  request.assignedWorkshop = workshop._id;
  request.assignedBy = req.user._id;
  request.assignmentMethod = 'admin_manual';
  request.distanceKm =
    Number.isFinite(request.latitude) &&
    Number.isFinite(request.longitude) &&
    Number.isFinite(workshop.latitude) &&
    Number.isFinite(workshop.longitude)
      ? Number(haversineKm(request.latitude, request.longitude, workshop.latitude, workshop.longitude).toFixed(2))
      : null;
  addHistory(request, 'assigned', req.user._id, 'Admin manual assignment');
  await request.save();
  await createNotification({
    userId: request.user,
    title: 'Emergency workshop assigned',
    body: `${workshop.name} was assigned to your request.`,
    type: 'emergency',
    data: { emergencyRequestId: request._id.toString(), workshopId: workshop._id.toString() },
  });
  await createNotification({
    userId: workshop.owner,
    title: 'Emergency request assigned',
    body: 'Admin assigned an emergency request to your workshop.',
    type: 'emergency',
    data: { emergencyRequestId: request._id.toString() },
  });
  const owner = await User.findById(workshop.owner).select('name email');
  await sendEmergencyEmail({
    to: owner?.email,
    subject: 'Salahny emergency request assigned by admin',
    lines: [
      `Hello ${owner?.name || workshop.name},`,
      'Admin assigned an emergency request to your workshop.',
      request.address ? `Address: ${request.address}` : '',
      'Open Salahny Workshop Dashboard to respond.',
    ],
  });
  const populated = await populateRequest(EmergencyRequest.findById(request._id));
  res.status(200).json({ success: true, data: toPayload(populated) });
});

const ensureEmergencyAccess = async (id, user) => {
  const request = await populateRequest(EmergencyRequest.findById(id));
  if (!request) throw Object.assign(new Error('Emergency request not found'), { statusCode: 404 });
  const ownsWorkshop = request.assignedWorkshop?.owner?._id?.toString() === user._id.toString();
  if (user.role !== 'admin' && request.user._id.toString() !== user._id.toString() && !ownsWorkshop) {
    throw Object.assign(new Error('Access denied'), { statusCode: 403 });
  }
  return request;
};

const mapMessage = (message, currentUserId) => ({
  id: message._id.toString(),
  text: message.text,
  senderId: message.sender?._id?.toString?.() ?? '',
  senderName: message.sender?.name ?? '',
  senderRole: message.senderRole,
  time: message.createdAt,
  isMe: message.sender?._id?.toString?.() === currentUserId,
});

export const getEmergencyMessages = asyncHandler(async (req, res) => {
  try {
    await ensureEmergencyAccess(req.params.id, req.user);
  } catch (error) {
    return res.status(error.statusCode || 500).json({ success: false, message: error.message });
  }
  const messages = await EmergencyMessage.find({ emergencyRequest: req.params.id })
    .populate('sender', 'name')
    .sort({ createdAt: 1 });
  res.status(200).json({ success: true, data: messages.map((item) => mapMessage(item, req.user._id.toString())) });
});

export const sendEmergencyMessage = asyncHandler(async (req, res) => {
  const { text } = req.body;
  if (!text?.trim()) return res.status(400).json({ success: false, message: 'Message text is required' });
  let request;
  try {
    request = await ensureEmergencyAccess(req.params.id, req.user);
  } catch (error) {
    return res.status(error.statusCode || 500).json({ success: false, message: error.message });
  }
  const message = await EmergencyMessage.create({
    emergencyRequest: request._id,
    sender: req.user._id,
    senderRole: req.user.role,
    text: text.trim(),
  });
  const recipients = [request.user?._id, request.assignedWorkshop?.owner?._id]
    .filter(Boolean)
    .filter((id) => id.toString() !== req.user._id.toString());
  await Promise.all(
    recipients.map((userId) =>
      createNotification({ userId, title: 'Emergency chat message', body: text.trim(), type: 'chat' }),
    ),
  );
  if (req.user.role !== 'admin') await notifyAdmins('Emergency chat message', text.trim());
  const populated = await message.populate('sender', 'name');
  res.status(201).json({ success: true, data: mapMessage(populated, req.user._id.toString()) });
});

export const getEmergencyStats = async () => ({
  total: await EmergencyRequest.countDocuments(),
  pending: await EmergencyRequest.countDocuments({ status: { $in: ['pending', 'pending_admin_assignment'] } }),
  active: await EmergencyRequest.countDocuments({ status: { $in: activeStatuses } }),
  completed: await EmergencyRequest.countDocuments({ status: 'completed' }),
});
