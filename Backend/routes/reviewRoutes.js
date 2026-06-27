import express from 'express';

import { createReview, getBookingReviews } from '../controllers/reviewController.js';
import { protect } from '../middleware/authMiddleware.js';
import { authorize } from '../middleware/roleMiddleware.js';

const router = express.Router();

router.use(protect);
router.post('/', authorize('driver', 'workshop'), createReview);
router.get('/booking/:bookingId', authorize('driver', 'workshop', 'admin'), getBookingReviews);

export default router;
