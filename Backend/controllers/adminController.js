import Booking from '../models/Booking.js';
import PackagePurchase from '../models/PackagePurchase.js';
import ServicePackage from '../models/Package.js';
import Service from '../models/Service.js';
import User from '../models/User.js';
import Workshop from '../models/Workshop.js';
import ActivityLog from '../models/ActivityLog.js';
import AdminWorkshopMessage from '../models/AdminWorkshopMessage.js';
import asyncHandler from '../utils/asyncHandler.js';
import { logActivity } from '../utils/activityLogger.js';
import { ensureAdminUser } from '../utils/ensureAdminUser.js';
import { createNotification } from './notificationController.js';
import { sendAccountStatusEmail } from '../services/emailService.js';
import {
  deleteDriverRelatedData,
  deleteWorkshopRelatedData,
} from '../utils/cascadeDelete.js';
import VerificationDocument from '../models/VerificationDocument.js';
import ChatMessage from '../models/ChatMessage.js';
import Diagnostic from '../models/Diagnostic.js';
import Earning from '../models/Earning.js';
import {
  getAdminDriverMessages,
  sendAdminDriverMessage,
} from './directMessageController.js';
import { emitWorkshopAdminMessage } from '../services/realtimeService.js';
import {
  assignEmergencyWorkshop,
  getAdminEmergencyRequests,
  getEmergencyMessages,
  getEmergencyStats,
} from './emergencyController.js';

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
    latitude: workshop.latitude,
    longitude: workshop.longitude,
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

const mapAdminWorkshopMessage = (message, currentUserId) => ({
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
  const [
    drivers,
    workshops,
    bookings,
    services,
    packages,
    logs,
    purchases,
    monthlyRevenue,
    topWorkshops,
    activeSubscribers,
      pendingDocuments,
    emergencyStats,
  ] =
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
      Booking.aggregate([
        {
          $group: {
            _id: {
              year: { $year: '$createdAt' },
              month: { $month: '$createdAt' },
            },
            total: { $sum: '$total' },
          },
        },
        { $sort: { '_id.year': 1, '_id.month': 1 } },
        { $limit: 6 },
      ]),
      Booking.aggregate([
        { $group: { _id: '$workshop', bookings: { $sum: 1 }, revenue: { $sum: '$total' } } },
        { $sort: { revenue: -1 } },
        { $limit: 5 },
      ]),
      PackagePurchase.countDocuments({
        status: { $in: ['paid', 'success'] },
        endsAt: { $gt: new Date() },
      }),
      VerificationDocument.countDocuments({
        status: { $in: ['pending', 'pending_upload', 'ai_processing', 'ai_verified', 'needs_admin_review'] },
      }),
      getEmergencyStats(),
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
        activeSubscribers,
        pendingDocuments,
        emergencyRequests: emergencyStats.total,
        activeEmergencyRequests: emergencyStats.active,
      },
      analytics: {
        bookingsByStatus: {
          pending: bookings.filter((item) => item.status === 'pending').length,
          active: bookings.filter((item) =>
            ['accepted', 'in_progress', 'diagnostics_ready', 'repair_in_progress'].includes(item.status),
          ).length,
          completed: bookings.filter((item) => item.status === 'completed').length,
          cancelled: bookings.filter((item) => ['cancelled', 'rejected'].includes(item.status)).length,
        },
        revenueByMonth: monthlyRevenue.map((item) => ({
          year: item._id.year,
          month: item._id.month,
          total: item.total,
        })),
        topWorkshops: await Promise.all(
          topWorkshops.map(async (item) => {
            const workshop = await Workshop.findById(item._id).select('name');
            return {
              id: item._id?.toString() ?? '',
              name: workshop?.name ?? 'Unknown Workshop',
              bookings: item.bookings,
              revenue: item.revenue,
            };
          }),
        ),
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
  const { status, notes = '', reviewNotes = '' } = req.body;
  const adminNotes = (reviewNotes || notes || '').toString().trim();
  if (!['pending', 'active', 'suspended', 'rejected', 'deleted'].includes(status)) {
    return res.status(400).json({ success: false, message: 'Invalid account status' });
  }
  const user = await User.findById(req.params.id);

  if (!user) {
    return res.status(404).json({ success: false, message: 'User not found' });
  }

  if (status === 'active' && user.role === 'driver') {
    const approvedLicense = await VerificationDocument.exists({
      owner: user._id,
      kind: 'driver_license',
      status: 'approved',
    });
    if (!approvedLicense) {
      return res.status(409).json({
        success: false,
        message: 'Review and approve the driver license before activating this driver',
      });
    }
  }

  user.accountStatus = status;
  if (status === 'rejected') {
    user.rejectionReason = adminNotes;
    user.verificationStatus = 'admin_rejected';
  } else if (status === 'active') {
    user.verificationStatus = 'admin_approved';
    user.rejectionReason = '';
  }
  await user.save();
  await createNotification({
    userId: user._id,
    title: status === 'active' ? 'Account approved' : 'Account status updated',
    body:
      status === 'active'
        ? 'Your Salahny account has been approved. You can now log in.'
        : status === 'rejected'
          ? `Your account verification was rejected.${adminNotes ? ` Notes: ${adminNotes}` : ''}`
          : `Your account status changed to ${status}.`,
    type: 'system',
    data: { accountStatus: status },
  });
  if (['active', 'rejected'].includes(status)) {
    await sendAccountStatusEmail({ user, status, notes: adminNotes });
  }
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
  if (user.role === 'driver') {
    await deleteDriverRelatedData(user._id);
  }

  if (user.role === 'workshop') {
    const workshops = await Workshop.find({ owner: user._id }).select('_id');
    await Promise.all(
      workshops.map((workshop) => deleteWorkshopRelatedData(workshop._id, user._id)),
    );
    await VerificationDocument.deleteMany({ owner: user._id });
  }

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

export const getAdminDocuments = asyncHandler(async (_req, res) => {
  const documents = await VerificationDocument.find()
    .populate('owner', 'name email role')
    .populate('workshop', 'name')
    .populate('reviewedBy', 'name email')
    .sort({ createdAt: -1 });
  res.status(200).json({ success: true, data: documents });
});

export const getAdminVerificationById = asyncHandler(async (req, res) => {
  const document = await VerificationDocument.findById(req.params.id)
    .populate('owner', 'name email role verificationStatus aiVerificationStatus aiConfidence aiExtractedFields aiIssues')
    .populate('workshop', 'name verificationStatus aiVerificationStatus aiConfidence aiExtractedFields aiIssues')
    .populate('reviewedBy', 'name email');
  if (!document) {
    return res.status(404).json({ success: false, message: 'Verification not found' });
  }
  res.status(200).json({ success: true, data: document });
});

export const reviewAdminDocument = asyncHandler(async (req, res) => {
  const { status, reviewNotes = '' } = req.body;
  if (!['approved', 'rejected'].includes(status)) {
    return res.status(400).json({
      success: false,
      message: 'status must be approved or rejected',
    });
  }

  const document = await VerificationDocument.findById(req.params.id);
  if (!document) {
    return res.status(404).json({ success: false, message: 'Document not found' });
  }

  document.status = status;
  document.reviewedBy = req.user._id;
  document.reviewNotes = reviewNotes;
  document.reviewedAt = new Date();
  await document.save();

  await User.findByIdAndUpdate(document.owner, {
    verificationStatus: status === 'approved' ? 'admin_approved' : 'admin_rejected',
    accountStatus: status === 'approved' ? 'active' : 'rejected',
    reviewedBy: req.user._id,
    reviewedAt: document.reviewedAt,
    rejectionReason: status === 'rejected' ? reviewNotes : '',
  });
  if (document.workshop) {
    await Workshop.findByIdAndUpdate(document.workshop, {
      isVerified: status === 'approved',
      accountStatus: status === 'approved' ? 'active' : 'rejected',
      verificationStatus: status === 'approved' ? 'admin_approved' : 'admin_rejected',
    });
  }
  const owner = await User.findById(document.owner);
  if (owner) {
    await createNotification({
      userId: owner._id,
      title: status === 'approved' ? 'Account approved' : 'Verification rejected',
      body:
        status === 'approved'
          ? 'Your Salahny account has been approved. You can now log in.'
          : `Your account verification was rejected.${reviewNotes ? ` Notes: ${reviewNotes}` : ''}`,
      type: 'system',
      data: { verificationDocumentId: document._id.toString(), status },
    });
    await sendAccountStatusEmail({
      user: owner,
      status: status === 'approved' ? 'active' : 'rejected',
      notes: reviewNotes,
    });
  }

  res.status(200).json({ success: true, data: document });
});

export const overrideAdminVerificationAi = asyncHandler(async (req, res) => {
  const { status, aiConfidence, aiExtractedFields = {}, aiIssues = [] } = req.body;
  if (!['ai_verified', 'ai_rejected', 'needs_admin_review'].includes(status)) {
    return res.status(400).json({
      success: false,
      message: 'status must be ai_verified, ai_rejected, or needs_admin_review',
    });
  }
  const document = await VerificationDocument.findById(req.params.id);
  if (!document) {
    return res.status(404).json({ success: false, message: 'Document not found' });
  }
  document.status = status;
  document.aiVerificationStatus = status;
  document.aiConfidence = aiConfidence ?? document.aiConfidence;
  document.aiExtractedFields = aiExtractedFields;
  document.aiIssues = Array.isArray(aiIssues) ? aiIssues.map(String) : [];
  document.aiCheckedAt = new Date();
  await document.save();
  await User.findByIdAndUpdate(document.owner, {
    verificationStatus: status,
    aiVerificationStatus: status,
    aiConfidence: document.aiConfidence,
    aiExtractedFields: document.aiExtractedFields,
    aiIssues: document.aiIssues,
  });
  if (document.workshop) {
    await Workshop.findByIdAndUpdate(document.workshop, {
      verificationStatus: status,
      aiVerificationStatus: status,
      aiConfidence: document.aiConfidence,
      aiExtractedFields: document.aiExtractedFields,
      aiIssues: document.aiIssues,
    });
  }
  res.status(200).json({ success: true, data: document });
});

export const getAdminBookingChats = asyncHandler(async (_req, res) => {
  const messages = await ChatMessage.find()
    .populate({
      path: 'booking',
      select: 'service status date user workshop',
      populate: [
        { path: 'user', select: 'name email phone' },
        { path: 'workshop', select: 'name location' },
      ],
    })
    .populate('sender', 'name role')
    .sort({ createdAt: -1 })
    .limit(200);
  res.status(200).json({
    success: true,
    data: messages.map((message) => ({
      id: message._id.toString(),
      bookingId: message.booking?._id?.toString() ?? '',
      serviceName: message.booking?.service ?? '',
      bookingStatus: message.booking?.status ?? '',
      bookingDate: message.booking?.date ?? null,
      driver: message.booking?.user
        ? {
            id: message.booking.user._id.toString(),
            name: message.booking.user.name,
            email: message.booking.user.email,
            phone: message.booking.user.phone,
          }
        : null,
      workshop: message.booking?.workshop
        ? {
            id: message.booking.workshop._id.toString(),
            name: message.booking.workshop.name,
            location: message.booking.workshop.location,
          }
        : null,
      senderId: message.sender?._id?.toString() ?? '',
      senderName: message.sender?.name ?? '',
      senderRole: message.senderRole,
      text: message.text,
      createdAt: message.createdAt,
    })),
  });
});

export const getAdminDiagnostics = asyncHandler(async (_req, res) => {
  const diagnostics = await Diagnostic.find()
    .populate('user', 'name email phone')
    .sort({ createdAt: -1 });
  res.status(200).json({
    success: true,
    data: diagnostics.map((item) => ({
      id: item._id.toString(),
      driver: item.user
        ? { id: item.user._id.toString(), name: item.user.name, email: item.user.email, phone: item.user.phone }
        : null,
      vehicleId: item.vehicleId,
      summary: item.summary,
      severity: item.riskLevel,
      probability: item.aiPrediction?.confidence ?? null,
      status: item.status,
      createdAt: item.createdAt,
    })),
  });
});

export const getAdminEarnings = asyncHandler(async (_req, res) => {
  const earnings = await Earning.find()
    .populate('workshop', 'name')
    .populate('booking', 'service')
    .populate('driver', 'name')
    .sort({ createdAt: -1 });
  res.status(200).json({
    success: true,
    data: earnings.map((item) => ({
      id: item._id.toString(),
      workshopId: item.workshop?._id?.toString() ?? '',
      workshopName: item.workshop?.name ?? '',
      bookingId: item.booking?._id?.toString() ?? '',
      serviceName: item.booking?.service ?? '',
      driverName: item.driver?.name ?? '',
      amount: item.amount,
      status: item.status,
      createdAt: item.createdAt,
    })),
  });
});

export {
  assignEmergencyWorkshop,
  getAdminEmergencyRequests,
  getEmergencyMessages as getAdminEmergencyMessages,
};

export { getAdminDriverMessages, sendAdminDriverMessage };

export const getPackageSubscribers = asyncHandler(async (req, res) => {
  const purchases = await PackagePurchase.find({ package: req.params.id })
    .populate('user', 'name email phone')
    .sort({ createdAt: -1 });
  res.status(200).json({
    success: true,
    count: purchases.length,
    data: purchases.map((purchase) => ({
      id: purchase._id.toString(),
      userId: purchase.user?._id?.toString() ?? '',
      name: purchase.user?.name ?? '',
      email: purchase.user?.email ?? '',
      phone: purchase.user?.phone ?? '',
      amount: purchase.amount,
      status: purchase.status,
      createdAt: purchase.createdAt,
    })),
  });
});

export const getAdminWorkshopMessages = asyncHandler(async (req, res) => {
  const workshop = await Workshop.findById(req.params.id).populate('owner', 'name email');
  if (!workshop) {
    return res.status(404).json({ success: false, message: 'Workshop not found' });
  }

  const messages = await AdminWorkshopMessage.find({ workshop: workshop._id })
    .populate('sender', 'name role')
    .sort({ createdAt: 1 });

  await AdminWorkshopMessage.updateMany(
    { workshop: workshop._id, senderRole: 'workshop', readByAdmin: false },
    { readByAdmin: true },
  );

  res.status(200).json({
    success: true,
    data: {
      workshop: {
        id: workshop._id.toString(),
        name: workshop.name,
        ownerName: workshop.owner?.name ?? '',
        ownerEmail: workshop.owner?.email ?? '',
      },
      messages: messages.map((message) =>
        mapAdminWorkshopMessage(message, req.user._id.toString()),
      ),
    },
  });
});

export const sendAdminWorkshopMessage = asyncHandler(async (req, res) => {
  const { text } = req.body;
  if (!text || !text.trim()) {
    return res.status(400).json({ success: false, message: 'Message text is required' });
  }

  const workshop = await Workshop.findById(req.params.id).populate('owner', 'name');
  if (!workshop) {
    return res.status(404).json({ success: false, message: 'Workshop not found' });
  }

  const message = await AdminWorkshopMessage.create({
    workshop: workshop._id,
    sender: req.user._id,
    senderRole: 'admin',
    text: text.trim(),
    readByAdmin: true,
    readByWorkshop: false,
  });

  await createNotification({
    userId: workshop.owner?._id ?? workshop.owner,
    title: 'Admin message',
    body: text.trim(),
    type: 'chat',
  });
  await logActivity({
    actor: req.user.name,
    actorRole: req.user.role,
    action: 'Admin messaged workshop',
    target: workshop.name,
    details: text.trim(),
  });

  const populated = await message.populate('sender', 'name role');
  emitWorkshopAdminMessage(workshop._id, mapAdminWorkshopMessage(populated, ''));
  res.status(201).json({
    success: true,
    data: mapAdminWorkshopMessage(populated, req.user._id.toString()),
  });
});
