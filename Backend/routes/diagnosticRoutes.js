import express from 'express';

import {
  getDiagnosticHistory,
  runDiagnosticScan,
} from '../controllers/diagnosticController.js';
import { protect } from '../middleware/authMiddleware.js';
import { authorize } from '../middleware/roleMiddleware.js';

const router = express.Router();

router.get('/', protect, authorize('driver', 'admin'), getDiagnosticHistory);
router.post('/scan', protect, authorize('driver', 'admin'), runDiagnosticScan);

export default router;
