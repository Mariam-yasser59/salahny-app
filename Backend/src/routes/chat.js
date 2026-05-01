const express = require('express');
const Message = require('../models/Message');
const ChatRoom = require('../models/ChatRoom');
const { auth } = require('../middleware/auth');

const router = express.Router();

const roomId = (a, b) => [a, b].sort().join('_');

// GET /chat/rooms
router.get('/rooms', auth, async (req, res) => {
  const rooms = await ChatRoom.find({ participants: req.user._id.toString() }).sort({ lastMessageAt: -1 });
  res.json(rooms);
});

// GET /chat/:recipientId/messages
router.get('/:recipientId/messages', auth, async (req, res) => {
  const rid = roomId(req.user._id.toString(), req.params.recipientId);
  const limit = Math.min(parseInt(req.query.limit) || 50, 200);
  const messages = await Message.find({ roomId: rid }).sort({ createdAt: 1 }).limit(limit);
  res.json(messages);
});

// POST /chat/:recipientId/messages  (REST fallback — use Socket.io for real-time)
router.post('/:recipientId/messages', auth, async (req, res) => {
  try {
    const uid = req.user._id.toString();
    const rid = roomId(uid, req.params.recipientId);
    const now = new Date();

    const msg = await Message.create({
      roomId: rid,
      senderId: uid,
      senderName: req.user.name,
      recipientId: req.params.recipientId,
      text: req.body.text,
    });

    await ChatRoom.findOneAndUpdate(
      { roomId: rid },
      { roomId: rid, participants: [uid, req.params.recipientId], lastMessage: req.body.text, lastMessageAt: now },
      { upsert: true },
    );

    res.status(201).json(msg);
  } catch (err) {
    res.status(500).json({ detail: err.message });
  }
});

// PUT /chat/:recipientId/messages/read
router.put('/:recipientId/messages/read', auth, async (req, res) => {
  const rid = roomId(req.user._id.toString(), req.params.recipientId);
  await Message.updateMany({ roomId: rid, recipientId: req.user._id.toString(), isRead: false }, { isRead: true });
  res.json({ message: 'Messages marked as read' });
});

module.exports = router;
