import express from 'express';

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

router.post('/register', register);
router.post('/login', login);
router.post('/google', googleLogin);
router.post('/forgot-password', requestPasswordReset);
router.post('/reset-password', resetPassword);
router.post('/refresh', refresh);
router.post('/logout', logout);

export default router;
