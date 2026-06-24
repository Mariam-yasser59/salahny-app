import express from 'express';

import {
  createPackagePurchase,
  createPackagePaymentIntent,
  getPaymentConfig,
  getPackagePurchases,
} from '../controllers/paymentController.js';
import { protect } from '../middleware/authMiddleware.js';
import { authorize } from '../middleware/roleMiddleware.js';

const router = express.Router();

router.get('/packages', protect, authorize('driver', 'admin'), getPackagePurchases);
router.get('/config', protect, authorize('driver', 'admin'), getPaymentConfig);
router.post('/packages', protect, authorize('driver', 'admin'), createPackagePurchase);
router.post('/packages/intent', protect, authorize('driver', 'admin'), createPackagePaymentIntent);

export default router;
