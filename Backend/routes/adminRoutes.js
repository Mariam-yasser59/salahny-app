import express from 'express';

import {
  deleteAdminUser,
  getAdminBookings,
  getAdminLogs,
  getAdminSnapshot,
  getAdminUsers,
  updateAdminBookingStatus,
  updateAdminUserStatus,
} from '../controllers/adminController.js';
import { protect } from '../middleware/authMiddleware.js';
import { authorize } from '../middleware/roleMiddleware.js';

const router = express.Router();

router.use(protect, authorize('admin'));

router.get('/dashboard', getAdminSnapshot);
router.get('/users', getAdminUsers);
router.patch('/users/:id/status', updateAdminUserStatus);
router.delete('/users/:id', deleteAdminUser);
router.get('/bookings', getAdminBookings);
router.patch('/bookings/:id/status', updateAdminBookingStatus);
router.get('/logs', getAdminLogs);

export default router;
