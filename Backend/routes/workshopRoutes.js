import express from 'express';

import {
  createWorkshop,
  deleteWorkshop,
  getWorkshopById,
  getNearbyWorkshops,
  getWorkshops,
  updateWorkshop,
} from '../controllers/workshopController.js';
import {
  getWorkshopEarnings,
  getWorkshopPortalDashboard,
} from '../controllers/workshopPortalController.js';
import { getWorkshopBookingDiagnostics } from '../controllers/diagnosticController.js';
import { optionalProtect, protect } from '../middleware/authMiddleware.js';
import { authorize } from '../middleware/roleMiddleware.js';

const router = express.Router();

router.get('/', optionalProtect, getWorkshops);
router.get('/nearby', optionalProtect, getNearbyWorkshops);
router.get('/dashboard', protect, authorize('workshop'), getWorkshopPortalDashboard);
router.get('/earnings', protect, authorize('workshop'), getWorkshopEarnings);
router.get('/diagnostics/:bookingId', protect, authorize('workshop'), getWorkshopBookingDiagnostics);
router.get('/:id', optionalProtect, getWorkshopById);
router.post('/', protect, authorize('workshop', 'admin'), createWorkshop);
router.put('/:id', protect, authorize('workshop', 'admin'), updateWorkshop);
router.delete('/:id', protect, authorize('workshop', 'admin'), deleteWorkshop);

export default router;
