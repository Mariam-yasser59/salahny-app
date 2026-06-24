import express from 'express';
import rateLimit from 'express-rate-limit';

import {
  getChatbotHistory,
  sendChatbotMessage,
} from '../controllers/chatbotController.js';
import { optionalProtect, protect } from '../middleware/authMiddleware.js';

const router = express.Router();

const chatbotLimiter = rateLimit({
  windowMs: 60 * 1000,
  limit: Number(process.env.CHATBOT_RATE_LIMIT_PER_MINUTE) || 12,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: 'Too many chatbot messages. Please wait a moment and try again.',
  },
});

router.post('/message', chatbotLimiter, optionalProtect, sendChatbotMessage);
router.get('/history', protect, getChatbotHistory);

export default router;
