import express from 'express';

import {
  documentUpload,
  uploadDocument,
} from '../controllers/documentController.js';
import { protect } from '../middleware/authMiddleware.js';

const router = express.Router();

router.post('/upload-document', protect, documentUpload.single('file'), uploadDocument);

export default router;
