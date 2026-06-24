import express from 'express';
import {
  acceptEmergencyRequest,
  cancelEmergencyRequest,
  createEmergencyRequest,
  getEmergencyById,
  getEmergencyMessages,
  getMyEmergencyRequests,
  getWorkshopEmergencyRequests,
  rejectEmergencyRequest,
  sendEmergencyMessage,
  updateEmergencyStatus,
} from '../controllers/emergencyController.js';
import { protect } from '../middleware/authMiddleware.js';
import { authorize } from '../middleware/roleMiddleware.js';

const router = express.Router();
router.use(protect);
router.post('/', authorize('driver'), createEmergencyRequest);
router.get('/my', authorize('driver'), getMyEmergencyRequests);
router.get('/workshop/assigned', authorize('workshop'), getWorkshopEmergencyRequests);
router.get('/:id', authorize('driver', 'workshop', 'admin'), getEmergencyById);
router.patch('/:id/cancel', authorize('driver'), cancelEmergencyRequest);
router.patch('/:id/accept', authorize('workshop'), acceptEmergencyRequest);
router.patch('/:id/reject', authorize('workshop'), rejectEmergencyRequest);
router.patch('/:id/status', authorize('workshop'), updateEmergencyStatus);
router.get('/:id/messages', authorize('driver', 'workshop', 'admin'), getEmergencyMessages);
router.post('/:id/messages', authorize('driver', 'workshop', 'admin'), sendEmergencyMessage);
export default router;
