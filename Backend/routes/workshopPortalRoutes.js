import express from 'express';

import {
  getWorkshopPortalBookings,
  getWorkshopPortalDashboard,
  updateWorkshopPortalBookingStatus,
} from '../controllers/workshopPortalController.js';
import { protect } from '../middleware/authMiddleware.js';
import { authorize } from '../middleware/roleMiddleware.js';

const router = express.Router();

router.use(protect, authorize('workshop', 'admin'));

router.get('/dashboard', getWorkshopPortalDashboard);
router.get('/bookings', getWorkshopPortalBookings);
router.patch('/bookings/:id/status', updateWorkshopPortalBookingStatus);

export default router;
