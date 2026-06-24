import express from 'express';
import {
  getDriverAdminMessages,
  sendDriverAdminMessage,
} from '../controllers/directMessageController.js';
import { protect } from '../middleware/authMiddleware.js';
import { authorize } from '../middleware/roleMiddleware.js';

const router = express.Router();
router.get('/admin', protect, authorize('driver'), getDriverAdminMessages);
router.post('/admin', protect, authorize('driver'), sendDriverAdminMessage);
export default router;
