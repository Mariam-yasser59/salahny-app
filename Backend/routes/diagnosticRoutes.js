import express from 'express';
import {
  diagnosticUpload,
  createRepairTaskFromDiagnostic,
  getDiagnosticById,
  getDiagnosticHistory,
  runDiagnosticScan,
  runWorkshopBookingDiagnostic,
  sendDiagnosticToDriver,
  uploadObdFile,
  uploadWorkshopBookingObdFile,
} from '../controllers/diagnosticController.js';
import { protect } from '../middleware/authMiddleware.js';
import { authorize } from '../middleware/roleMiddleware.js';

const router = express.Router();
router.use(protect);
router.get('/', authorize('driver', 'admin'), getDiagnosticHistory);
router.get('/my', authorize('driver'), getDiagnosticHistory);
router.post('/scan', authorize('driver', 'admin'), runDiagnosticScan);
router.post('/run', authorize('driver', 'admin'), runDiagnosticScan);
router.post('/upload-obd', authorize('driver'), diagnosticUpload.single('file'), uploadObdFile);
router.post('/workshop/:bookingId/run', authorize('workshop'), runWorkshopBookingDiagnostic);
router.post(
  '/workshop/:bookingId/upload-obd',
  authorize('workshop'),
  diagnosticUpload.single('file'),
  uploadWorkshopBookingObdFile,
);
router.post('/:id/send-to-driver', authorize('workshop', 'admin'), sendDiagnosticToDriver);
router.post('/:id/create-repair-task', authorize('workshop', 'admin'), createRepairTaskFromDiagnostic);
router.get('/:id', authorize('driver', 'admin'), getDiagnosticById);
export default router;
