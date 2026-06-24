import express from 'express';

import {
  aiChat,
  getBookingChatContext,
  getBookingChatThreads,
  getBookingMessages,
  sendBookingMessage,
  shareWorkshopDiagnostic,
} from '../controllers/chatController.js';
import { protect } from '../middleware/authMiddleware.js';
import { authorize } from '../middleware/roleMiddleware.js';

const router = express.Router();

router.post('/ai', protect, aiChat);
router.get('/bookings', protect, getBookingChatThreads);
router.get('/bookings/:bookingId/context', protect, getBookingChatContext);
router.get('/bookings/:bookingId/messages', protect, getBookingMessages);
router.post('/bookings/:bookingId/messages', protect, sendBookingMessage);
router.post(
  '/bookings/:bookingId/share-diagnostic',
  protect,
  authorize('workshop', 'admin'),
  shareWorkshopDiagnostic,
);

export default router;
