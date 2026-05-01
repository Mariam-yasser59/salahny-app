import express from 'express';

import {
  createWorkshop,
  deleteWorkshop,
  getWorkshopById,
  getWorkshops,
  updateWorkshop,
} from '../controllers/workshopController.js';
import { protect } from '../middleware/authMiddleware.js';
import { authorize } from '../middleware/roleMiddleware.js';

const router = express.Router();

router.get('/', getWorkshops);
router.get('/:id', getWorkshopById);
router.post('/', protect, authorize('workshop', 'admin'), createWorkshop);
router.put('/:id', protect, authorize('workshop', 'admin'), updateWorkshop);
router.delete('/:id', protect, authorize('workshop', 'admin'), deleteWorkshop);

export default router;
