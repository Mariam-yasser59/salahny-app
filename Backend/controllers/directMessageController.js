import DirectMessage from '../models/DirectMessage.js';
import User from '../models/User.js';
import asyncHandler from '../utils/asyncHandler.js';
import { createNotification } from './notificationController.js';
import { emitUserMessage } from '../services/realtimeService.js';
import { ensureAdminUser } from '../utils/ensureAdminUser.js';

const threadKeyFor = (a, b) => [a.toString(), b.toString()].sort().join(':');
const mapMessage = (message, currentUserId) => ({
  id: message._id.toString(),
  text: message.text,
  senderId: message.sender?._id?.toString?.() ?? message.sender?.toString() ?? '',
  senderRole: message.senderRole,
  senderName: message.sender?.name ?? 'User',
  time: message.createdAt,
  isMe:
    (message.sender?._id?.toString?.() ?? message.sender?.toString()) ===
    currentUserId,
});

const getAdmin = async () => {
  await ensureAdminUser();
  return User.findOne({
    role: 'admin',
    accountStatus: { $nin: ['suspended', 'rejected', 'deleted'] },
  }).sort({ createdAt: 1 });
};

export const getDriverAdminMessages = asyncHandler(async (req, res) => {
  const admin = await getAdmin();
  if (!admin) {
    return res.status(404).json({ success: false, message: 'Admin account not found' });
  }
  const messages = await DirectMessage.find({
    threadKey: threadKeyFor(req.user._id, admin._id),
  })
    .populate('sender', 'name')
    .sort({ createdAt: 1 });
  res.status(200).json({
    success: true,
    data: messages.map((message) => mapMessage(message, req.user._id.toString())),
  });
});

export const sendDriverAdminMessage = asyncHandler(async (req, res) => {
  const { text = '' } = req.body;
  if (!text.trim()) {
    return res.status(400).json({ success: false, message: 'Message text is required' });
  }
  const admin = await getAdmin();
  if (!admin) {
    return res.status(404).json({ success: false, message: 'Admin account not found' });
  }
  const message = await DirectMessage.create({
    threadKey: threadKeyFor(req.user._id, admin._id),
    participants: [req.user._id, admin._id],
    sender: req.user._id,
    senderRole: 'driver',
    text: text.trim(),
  });
  await createNotification({
    userId: admin._id,
    title: 'Driver message',
    body: text.trim(),
    type: 'chat',
  });
  const populated = await message.populate('sender', 'name');
  emitUserMessage(admin._id, mapMessage(populated, ''));
  emitUserMessage(req.user._id, mapMessage(populated, req.user._id.toString()));
  res.status(201).json({ success: true, data: mapMessage(populated, req.user._id.toString()) });
});

export const getAdminDriverMessages = asyncHandler(async (req, res) => {
  const driver = await User.findOne({ _id: req.params.driverId, role: 'driver' });
  if (!driver) {
    return res.status(404).json({ success: false, message: 'Driver not found' });
  }
  const messages = await DirectMessage.find({
    threadKey: threadKeyFor(req.user._id, driver._id),
  })
    .populate('sender', 'name')
    .sort({ createdAt: 1 });
  res.status(200).json({
    success: true,
    data: messages.map((message) => mapMessage(message, req.user._id.toString())),
  });
});

export const sendAdminDriverMessage = asyncHandler(async (req, res) => {
  const { text = '' } = req.body;
  if (!text.trim()) {
    return res.status(400).json({ success: false, message: 'Message text is required' });
  }
  const driver = await User.findOne({ _id: req.params.driverId, role: 'driver' });
  if (!driver) {
    return res.status(404).json({ success: false, message: 'Driver not found' });
  }
  const message = await DirectMessage.create({
    threadKey: threadKeyFor(req.user._id, driver._id),
    participants: [req.user._id, driver._id],
    sender: req.user._id,
    senderRole: 'admin',
    text: text.trim(),
  });
  await createNotification({
    userId: driver._id,
    title: 'Admin message',
    body: text.trim(),
    type: 'chat',
  });
  const populated = await message.populate('sender', 'name');
  emitUserMessage(driver._id, mapMessage(populated, ''));
  emitUserMessage(req.user._id, mapMessage(populated, req.user._id.toString()));
  res.status(201).json({ success: true, data: mapMessage(populated, req.user._id.toString()) });
});
