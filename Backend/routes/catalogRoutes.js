import express from 'express';

import {
  createPackage,
  createService,
  deletePackage,
  deleteService,
  getPackages,
  getServices,
  updatePackage,
  updateService,
} from '../controllers/catalogController.js';
import { protect } from '../middleware/authMiddleware.js';
import { authorize } from '../middleware/roleMiddleware.js';

const router = express.Router();

router.get('/services', getServices);
router.get('/packages', getPackages);
router.post('/services', protect, authorize('admin'), createService);
router.put('/services/:id', protect, authorize('admin'), updateService);
router.delete('/services/:id', protect, authorize('admin'), deleteService);
router.post('/packages', protect, authorize('admin'), createPackage);
router.put('/packages/:id', protect, authorize('admin'), updatePackage);
router.delete('/packages/:id', protect, authorize('admin'), deletePackage);

export default router;
