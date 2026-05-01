import express from 'express';

import {
  createBooking,
  getBookingById,
  getBookings,
  updateBookingStatus,
} from '../controllers/bookingController.js';
import { protect } from '../middleware/authMiddleware.js';
import { authorize } from '../middleware/roleMiddleware.js';

const router = express.Router();

router.get('/', protect, getBookings);
router.get('/:id', protect, getBookingById);
router.post('/', protect, authorize('driver', 'admin'), createBooking);
router.patch(
  '/:id/status',
  protect,
  authorize('workshop', 'admin'),
  updateBookingStatus,
);

export default router;
