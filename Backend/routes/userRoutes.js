import express from 'express';

import {
  getCurrentUser,
  getUserById,
  getUsers,
  updateCurrentUser,
} from '../controllers/userController.js';
import { protect } from '../middleware/authMiddleware.js';
import { authorize } from '../middleware/roleMiddleware.js';

const router = express.Router();

router.get('/me', protect, getCurrentUser);
router.put('/me', protect, updateCurrentUser);
router.get('/', protect, authorize('admin'), getUsers);
router.get('/:id', protect, authorize('admin'), getUserById);

export default router;
