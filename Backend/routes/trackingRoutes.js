import express from 'express';
import { addTrackingUpdate, getTrackingUpdates } from '../controllers/trackingController.js';
import { protect } from '../middleware/authMiddleware.js';
import { authorize } from '../middleware/roleMiddleware.js';

const router = express.Router();
router.get('/:bookingId', protect, getTrackingUpdates);
router.post('/:bookingId', protect, authorize('workshop', 'admin'), addTrackingUpdate);
export default router;
