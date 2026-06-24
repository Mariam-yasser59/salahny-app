import express from 'express';
import rateLimit from 'express-rate-limit';

import {
  googleLogin,
  login,
  logout,
  requestPasswordReset,
  refresh,
  register,
  resetPassword,
} from '../controllers/authController.js';

const router = express.Router();

const passwordResetLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 5,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    success: false,
    message: 'Too many password reset attempts. Please try again later.',
  },
});

router.post('/register', register);
router.post('/login', login);
router.post('/google', googleLogin);
router.post('/forgot-password', passwordResetLimiter, requestPasswordReset);
router.post('/reset-password', passwordResetLimiter, resetPassword);
router.post('/refresh', refresh);
router.post('/logout', logout);

export default router;
