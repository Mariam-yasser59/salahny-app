import express from 'express';

import {
  getNotificationSummary,
  getNotifications,
  markAllNotificationsRead,
  markNotificationRead,
  saveDeviceToken,
} from '../controllers/notificationController.js';
import { protect } from '../middleware/authMiddleware.js';

const router = express.Router();

router.get('/', protect, getNotifications);
router.get('/summary', protect, getNotificationSummary);
router.get('/unread-count', protect, getNotificationSummary);
router.patch('/read-all', protect, markAllNotificationsRead);
router.patch('/:id/read', protect, markNotificationRead);
router.post('/device-token', protect, saveDeviceToken);

export default router;
