import express from 'express';

import {
  addWorkshopService,
  deleteWorkshopService,
  getWorkshopAdminMessages,
  getWorkshopPortalServices,
  getWorkshopPortalSlots,
  getWorkshopEarnings,
  getWorkshopPortalBookings,
  getWorkshopPortalDashboard,
  sendWorkshopAdminMessage,
  updateWorkshopPortalBookingStatus,
  updateWorkshopPortalServices,
  updateWorkshopPortalSlots,
} from '../controllers/workshopPortalController.js';
import { protect } from '../middleware/authMiddleware.js';
import { authorize } from '../middleware/roleMiddleware.js';

const router = express.Router();

router.use(protect, authorize('workshop', 'admin'));

router.get('/dashboard', getWorkshopPortalDashboard);
router.get('/bookings', getWorkshopPortalBookings);
router.patch('/bookings/:id/status', updateWorkshopPortalBookingStatus);
router.get('/services', getWorkshopPortalServices);
router.get('/slots', getWorkshopPortalSlots);
router.get('/earnings', getWorkshopEarnings);
router.put('/slots', updateWorkshopPortalSlots);
router.put('/services', updateWorkshopPortalServices);
router.post('/services', addWorkshopService);
router.delete('/services/:serviceId', deleteWorkshopService);
router.get('/admin/messages', getWorkshopAdminMessages);
router.post('/admin/messages', sendWorkshopAdminMessage);

export default router;
