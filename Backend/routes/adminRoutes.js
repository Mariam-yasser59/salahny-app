import express from 'express';

import {
  deleteAdminUser,
  getAdminBookings,
  getAdminBookingChats,
  getAdminDocuments,
  getAdminLogs,
  getAdminSnapshot,
  getAdminWorkshopMessages,
  getAdminDriverMessages,
  getAdminUsers,
  sendAdminWorkshopMessage,
  sendAdminDriverMessage,
  updateAdminBookingStatus,
  updateAdminUserStatus,
  reviewAdminDocument,
  getAdminVerificationById,
  overrideAdminVerificationAi,
  getPackageSubscribers,
  getAdminDiagnostics,
  getAdminEarnings,
  getAdminEmergencyRequests,
  assignEmergencyWorkshop,
  getAdminEmergencyMessages,
} from '../controllers/adminController.js';
import { reverifyDocument } from '../controllers/documentController.js';
import { protect } from '../middleware/authMiddleware.js';
import { authorize } from '../middleware/roleMiddleware.js';

const router = express.Router();

router.use(protect, authorize('admin'));

router.get('/dashboard', getAdminSnapshot);
router.get('/users', getAdminUsers);
router.patch('/users/:id/status', updateAdminUserStatus);
router.delete('/users/:id', deleteAdminUser);
router.get('/bookings', getAdminBookings);
router.patch('/bookings/:id/status', updateAdminBookingStatus);
router.get('/logs', getAdminLogs);
router.get('/documents', getAdminDocuments);
router.patch('/documents/:id/review', reviewAdminDocument);
router.get('/verifications', getAdminDocuments);
router.get('/verifications/:id', getAdminVerificationById);
router.patch('/verifications/:id/approve', (req, _res, next) => {
  req.body.status = 'approved';
  next();
}, reviewAdminDocument);
router.patch('/verifications/:id/reject', (req, _res, next) => {
  req.body.status = 'rejected';
  next();
}, reviewAdminDocument);
router.patch('/verifications/:id/request-reupload', (req, _res, next) => {
  req.body.status = 'request_reupload';
  next();
}, reviewAdminDocument);
router.patch('/verifications/:id/override-ai', overrideAdminVerificationAi);
router.post('/verifications/:id/reverify', reverifyDocument);
router.get('/chats/bookings', getAdminBookingChats);
router.get('/diagnostics', getAdminDiagnostics);
router.get('/earnings', getAdminEarnings);
router.get('/emergency', getAdminEmergencyRequests);
router.get('/emergency/:id/chat', getAdminEmergencyMessages);
router.patch('/emergency/:id/assign-workshop', assignEmergencyWorkshop);
router.patch('/emergency/:id/reassign-workshop', assignEmergencyWorkshop);
router.get('/drivers/:driverId/messages', getAdminDriverMessages);
router.post('/drivers/:driverId/messages', sendAdminDriverMessage);
router.get('/packages/:id/subscribers', getPackageSubscribers);
router.get('/workshops/:id/messages', getAdminWorkshopMessages);
router.post('/workshops/:id/messages', sendAdminWorkshopMessage);

export default router;
