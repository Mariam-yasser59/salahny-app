import Booking from '../models/Booking.js';
import ChatMessage from '../models/ChatMessage.js';
import Diagnostic from '../models/Diagnostic.js';
import Workshop from '../models/Workshop.js';
import asyncHandler from '../utils/asyncHandler.js';
import { createNotification } from './notificationController.js';

const ensureBookingAccess = async (bookingId, user) => {
  const booking = await Booking.findById(bookingId)
    .populate('user', 'name phone email')
    .populate('workshop', 'name owner');

  if (!booking) {
    throw Object.assign(new Error('Booking not found'), { statusCode: 404 });
  }

  const isDriver = booking.user?._id?.toString() === user._id.toString();
  const isWorkshopOwner = booking.workshop?.owner?.toString() === user._id.toString();
  const isAdmin = user.role === 'admin';

  if (!isDriver && !isWorkshopOwner && !isAdmin) {
    throw Object.assign(new Error('Access denied'), { statusCode: 403 });
  }

  return booking;
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
});

const generateAiReply = (message, report, booking) => {
  const intro = booking
    ? `For your ${booking.service} booking with ${booking.workshop?.name ?? 'the workshop'}, `
    : 'For your vehicle, ';
  if (report?.aiPrediction) {
    return `${intro}the latest AI diagnostic points to ${report.aiPrediction.issue} with ${(report.aiPrediction.confidence * 100).toFixed(0)}% confidence. ${report.aiPrediction.recommendation} You asked: "${message}".`;
  }
  return `${intro}I can help with maintenance, diagnostics, and booking follow-up. Based on your message "${message}", I recommend sharing sensor readings or running a fresh scan for a more precise answer.`;
};

export const getBookingMessages = asyncHandler(async (req, res) => {
  try {
    await ensureBookingAccess(req.params.bookingId, req.user);
  } catch (error) {
    return res.status(error.statusCode || 500).json({
      success: false,
      message: error.message,
    });
  }

  const messages = await ChatMessage.find({ booking: req.params.bookingId })
    .populate('sender', 'name')
    .sort({ createdAt: 1 });

  res.status(200).json({
    success: true,
    data: messages.map((message) => mapMessage(message, req.user._id.toString())),
  });
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
    req.user.role === 'workshop' ? booking.user?._id : booking.workshop?.owner;
  if (recipientId) {
    await createNotification({
      userId: recipientId,
      title: req.user.role === 'workshop' ? 'Workshop message' : 'Driver message',
      body: text.trim(),
      type: 'chat',
    });
  }

  const populated = await message.populate('sender', 'name');
  res.status(201).json({
    success: true,
    data: mapMessage(populated, req.user._id.toString()),
  });
});

export const aiChat = asyncHandler(async (req, res) => {
  const { message = '', bookingId } = req.body;
  if (!message.trim()) {
    return res.status(400).json({ success: false, message: 'Message is required' });
  }

  let booking = null;
  if (bookingId) {
    booking = await Booking.findById(bookingId).populate('workshop', 'name');
  }

  const report = await Diagnostic.findOne({ user: req.user._id }).sort({ createdAt: -1 });
  const reply = generateAiReply(message.trim(), report, booking);

  res.status(200).json({
    success: true,
    data: {
      reply,
      diagnosticSummary: report
        ? {
            summary: report.summary,
            riskLevel: report.riskLevel,
            confidence: report.aiPrediction?.confidence ?? null,
          }
        : null,
    },
  });
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
  res.status(201).json({
    success: true,
    data: mapMessage(populated, req.user._id.toString()),
  });
});
