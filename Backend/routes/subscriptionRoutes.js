import express from 'express';

import { createDemoOnlineSubscriptionPayment } from '../controllers/paymentController.js';
import { protect } from '../middleware/authMiddleware.js';
import { authorize } from '../middleware/roleMiddleware.js';

const router = express.Router();

router.post(
  '/demo-online-payment',
  protect,
  authorize('driver', 'admin'),
  createDemoOnlineSubscriptionPayment,
);

export default router;
