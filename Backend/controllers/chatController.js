import Booking from '../models/Booking.js';
import ChatMessage from '../models/ChatMessage.js';
import Workshop from '../models/Workshop.js';
import asyncHandler from '../utils/asyncHandler.js';
import { createNotification } from './notificationController.js';
import { emitBookingMessage } from '../services/realtimeService.js';
import { sendChatbotMessage } from './chatbotController.js';

const ensureBookingAccess = async (bookingId, user) => {
  const booking = await Booking.findById(bookingId)
    .populate('user', 'name phone email')
    .populate({
      path: 'workshop',
      select: 'name owner phone location',
      populate: { path: 'owner', select: 'name phone email' },
    });

  if (!booking) {
    throw Object.assign(new Error('Booking not found'), { statusCode: 404 });
  }

  const isDriver = booking.user?._id?.toString() === user._id.toString();
  const workshopOwnerId =
    booking.workshop?.owner?._id?.toString?.() ?? booking.workshop?.owner?.toString?.();
  const isWorkshopOwner = workshopOwnerId === user._id.toString();
  const isAdmin = user.role === 'admin';

  if (!isDriver && !isWorkshopOwner && !isAdmin) {
    throw Object.assign(new Error('Access denied'), { statusCode: 403 });
  }

  return booking;
};

const getWorkshopOwnerId = (booking) =>
  booking.workshop?.owner?._id?.toString?.() ?? booking.workshop?.owner?.toString?.() ?? '';

const mapBookingContext = (booking, user) => {
  const isDriver = booking.user?._id?.toString() === user._id.toString();
  const workshopPhone = booking.workshop?.phone || booking.workshop?.owner?.phone || '';
  const driverPhone = booking.user?.phone || '';
  return {
    bookingId: booking._id.toString(),
    service: booking.service,
    status: booking.status,
    driver: {
      id: booking.user?._id?.toString?.() ?? '',
      name: booking.user?.name ?? 'Driver',
      phone: driverPhone,
    },
    workshop: {
      id: booking.workshop?._id?.toString?.() ?? '',
      name: booking.workshop?.name ?? 'Workshop',
      phone: workshopPhone,
      location: booking.workshop?.location ?? '',
      ownerId: getWorkshopOwnerId(booking),
    },
    peer: isDriver
      ? {
          role: 'workshop',
          name: booking.workshop?.name ?? 'Workshop',
          phone: workshopPhone,
        }
      : {
          role: 'driver',
          name: booking.user?.name ?? 'Driver',
          phone: driverPhone,
        },
  };
};

const mapMessage = (message, currentUserId) => ({
  id: message._id.toString(),
  text: message.text,
  senderId: message.sender?._id?.toString?.() ?? message.sender?.toString() ?? '',
  senderRole: message.senderRole,
  senderName: message.sender?.name ?? (message.senderRole === 'ai' ? 'AI Assistant' : 'Workshop'),
  time: message.createdAt,
  isMe:
    message.senderRole !== 'ai' &&
    (message.sender?._id?.toString?.() ?? message.sender?.toString()) === currentUserId,
  meta: message.meta ?? {},
  isRead:
    message.senderRole === 'ai' ||
    (message.readBy ?? []).some(
      (entry) => (entry.user?._id?.toString?.() ?? entry.user?.toString?.()) !== currentUserId,
    ),
});

export const getBookingMessages = asyncHandler(async (req, res) => {
  let booking;
  try {
    booking = await ensureBookingAccess(req.params.bookingId, req.user);
  } catch (error) {
    return res.status(error.statusCode || 500).json({
      success: false,
      message: error.message,
    });
  }

  await ChatMessage.updateMany(
    {
      booking: booking._id,
      sender: { $ne: req.user._id },
      'readBy.user': { $ne: req.user._id },
    },
    { $push: { readBy: { user: req.user._id, readAt: new Date() } } },
  );

  const messages = await ChatMessage.find({ booking: req.params.bookingId })
    .populate('sender', 'name')
    .sort({ createdAt: 1 });

  res.status(200).json({
    success: true,
    data: messages.map((message) => mapMessage(message, req.user._id.toString())),
  });
});

export const getBookingChatContext = asyncHandler(async (req, res) => {
  let booking;
  try {
    booking = await ensureBookingAccess(req.params.bookingId, req.user);
  } catch (error) {
    return res.status(error.statusCode || 500).json({
      success: false,
      message: error.message,
    });
  }

  res.status(200).json({ success: true, data: mapBookingContext(booking, req.user) });
});

export const getBookingChatThreads = asyncHandler(async (req, res) => {
  const query = req.user.role === 'workshop'
    ? { workshop: (await Workshop.findOne({ owner: req.user._id }))?._id }
    : req.user.role === 'admin'
      ? {}
      : { user: req.user._id };

  if (req.user.role === 'workshop' && !query.workshop) {
    return res.status(200).json({ success: true, data: [] });
  }

  const bookings = await Booking.find(query)
    .populate('user', 'name phone email')
    .populate({
      path: 'workshop',
      select: 'name owner phone location',
      populate: { path: 'owner', select: 'name phone email' },
    })
    .sort({ updatedAt: -1 })
    .limit(100);

  const data = await Promise.all(
    bookings.map(async (booking) => {
      const latest = await ChatMessage.findOne({ booking: booking._id })
        .populate('sender', 'name')
        .sort({ createdAt: -1 });
      const unread = await ChatMessage.countDocuments({
        booking: booking._id,
        sender: { $ne: req.user._id },
        'readBy.user': { $ne: req.user._id },
      });
      return {
        ...mapBookingContext(booking, req.user),
        latestMessage: latest ? mapMessage(latest, req.user._id.toString()) : null,
        unread,
      };
    }),
  );

  res.status(200).json({ success: true, data });
});

export const sendBookingMessage = asyncHandler(async (req, res) => {
  const { text } = req.body;
  if (!text || !text.trim()) {
    return res.status(400).json({ success: false, message: 'Message text is required' });
  }

  let booking;
  try {
    booking = await ensureBookingAccess(req.params.bookingId, req.user);
  } catch (error) {
    return res.status(error.statusCode || 500).json({
      success: false,
      message: error.message,
    });
  }

  const message = await ChatMessage.create({
    booking: booking._id,
    sender: req.user._id,
    senderRole: req.user.role,
    text: text.trim(),
  });

  const recipientId =
    req.user.role === 'workshop' ? booking.user?._id : getWorkshopOwnerId(booking);
  if (recipientId) {
    await createNotification({
      userId: recipientId,
      title: req.user.role === 'workshop' ? 'Workshop message' : 'Driver message',
      body: text.trim(),
      type: 'chat',
    });
  }

  const populated = await message.populate('sender', 'name');
  emitBookingMessage(booking._id.toString(), mapMessage(populated, ''));
  res.status(201).json({
    success: true,
    data: mapMessage(populated, req.user._id.toString()),
  });
});

export const aiChat = asyncHandler(async (req, res) => {
  return sendChatbotMessage(req, res);
});

export const shareWorkshopDiagnostic = asyncHandler(async (req, res) => {
  const { bookingId } = req.params;
  const { summary, recommendation } = req.body;

  const workshop = await Workshop.findOne({ owner: req.user._id });
  const booking = await Booking.findById(bookingId).populate('user', 'name');
  if (!workshop || !booking || booking.workshop.toString() !== workshop._id.toString()) {
    return res.status(404).json({
      success: false,
      message: 'Booking not found for this workshop',
    });
  }

  const message = await ChatMessage.create({
    booking: booking._id,
    sender: req.user._id,
    senderRole: 'workshop',
    text: `Diagnostic update: ${summary}. Recommendation: ${recommendation}`,
    meta: {
      source: 'diagnostic_share',
    },
  });

  await createNotification({
    userId: booking.user._id,
    title: 'Diagnostic report ready',
    body: `${workshop.name} shared a diagnostic update for your booking.`,
    type: 'diagnostic',
  });

  const populated = await message.populate('sender', 'name');
  emitBookingMessage(booking._id.toString(), mapMessage(populated, ''));
  res.status(201).json({
    success: true,
    data: mapMessage(populated, req.user._id.toString()),
  });
});
