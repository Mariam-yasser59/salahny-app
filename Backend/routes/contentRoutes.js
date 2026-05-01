import express from 'express';

import {
  getAdminSettings,
  getPublicContent,
  updateAdminPassword,
  updateAdminSettings,
} from '../controllers/contentController.js';
import { protect } from '../middleware/authMiddleware.js';
import { authorize } from '../middleware/roleMiddleware.js';

const router = express.Router();

router.get('/public-content', getPublicContent);
router.get('/admin/settings', protect, authorize('admin'), getAdminSettings);
router.put('/admin/settings', protect, authorize('admin'), updateAdminSettings);
router.put('/admin/settings/password', protect, authorize('admin'), updateAdminPassword);

export default router;
