import express from 'express';

import {
  createPackagePurchase,
  getPackagePurchases,
} from '../controllers/paymentController.js';
import { protect } from '../middleware/authMiddleware.js';
import { authorize } from '../middleware/roleMiddleware.js';

const router = express.Router();

router.get('/packages', protect, authorize('driver', 'admin'), getPackagePurchases);
router.post('/packages', protect, authorize('driver', 'admin'), createPackagePurchase);

export default router;
