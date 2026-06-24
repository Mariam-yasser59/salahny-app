import express from 'express';

import {
  documentUpload,
  getDocumentFile,
  getMyDocuments,
  reverifyDocument,
  uploadDocument,
} from '../controllers/documentController.js';
import { protect } from '../middleware/authMiddleware.js';

const router = express.Router();

router.use(protect);
router.get('/me', getMyDocuments);
router.post('/', documentUpload.single('file'), uploadDocument);
router.post('/:id/reverify', reverifyDocument);
router.get('/:id/file', getDocumentFile);

export default router;
