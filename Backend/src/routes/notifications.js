const express = require('express');
const Notification = require('../models/Notification');
const { auth } = require('../middleware/auth');

const router = express.Router();

// GET /notifications
router.get('/', auth, async (req, res) => {
  const notifications = await Notification.find({ userId: req.user._id.toString() }).sort({ createdAt: -1 }).limit(50);
  res.json(notifications);
});

// GET /notifications/unread-count
router.get('/unread-count', auth, async (req, res) => {
  const count = await Notification.countDocuments({ userId: req.user._id.toString(), isRead: false });
  res.json({ count });
});

// PUT /notifications/read-all
router.put('/read-all', auth, async (req, res) => {
  await Notification.updateMany({ userId: req.user._id.toString(), isRead: false }, { isRead: true });
  res.json({ message: 'All notifications marked as read' });
});

// PUT /notifications/:id/read
router.put('/:id/read', auth, async (req, res) => {
  try {
    const n = await Notification.findOneAndUpdate(
      { _id: req.params.id, userId: req.user._id.toString() },
      { isRead: true },
      { new: true },
    );
    if (!n) return res.status(404).json({ detail: 'Notification not found' });
    res.json(n);
  } catch {
    res.status(400).json({ detail: 'Invalid notification ID' });
  }
});

module.exports = router;
