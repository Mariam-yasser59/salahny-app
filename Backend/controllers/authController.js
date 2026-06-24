import User from '../models/User.js';
import RefreshToken from '../models/RefreshToken.js';
import {
  ensureAdminUser,
  isDefaultAdminEmail,
  isUnsafeDemoAdminLogin,
} from '../utils/ensureAdminUser.js';
import asyncHandler from '../utils/asyncHandler.js';
import crypto from 'crypto';
import jwt from 'jsonwebtoken';
import { OAuth2Client } from 'google-auth-library';
import generateToken, { generateRefreshToken } from '../utils/generateToken.js';
import { sendEmail } from '../services/emailService.js';

const hashToken = (token) =>
  crypto.createHash('sha256').update(token).digest('hex');

const buildPasswordResetEmail = ({ user, resetToken }) => {
  const resetBaseUrl =
    process.env.PASSWORD_RESET_URL_BASE || process.env.FRONTEND_URL || '';

  const resetUrl = resetBaseUrl
    ? `${resetBaseUrl.replace(
        /\/$/,
        '',
      )}/#/forgot-password?token=${encodeURIComponent(resetToken)}`
    : '';

  const expiresText = 'This reset token expires in 15 minutes.';

  const text = [
    `Hello ${user.name},`,
    '',
    'We received a request to reset your Salahny password.',
    '',
    `Reset token: ${resetToken}`,
    resetUrl ? `Reset link: ${resetUrl}` : '',
    '',
    expiresText,
    'If you did not request this, you can safely ignore this email.',
    '',
    'Salahny Team',
  ]
    .filter((line) => line !== '')
    .join('\n');

  const html = `
    <div style="font-family:Arial,sans-serif;line-height:1.6;color:#111">
      <h2 style="color:#C9182B">Reset your Salahny password</h2>
      <p>Hello ${user.name},</p>
      <p>We received a request to reset your Salahny password.</p>
      <p style="font-size:14px;color:#555">Copy this reset token into the Salahny app:</p>
      <div style="font-size:20px;font-weight:700;letter-spacing:1px;padding:12px 16px;background:#f4f4f4;border-radius:8px;display:inline-block">${resetToken}</div>
      ${
        resetUrl
          ? `<p><a href="${resetUrl}" style="color:#C9182B">Open reset page</a></p>`
          : ''
      }
      <p>${expiresText}</p>
      <p>If you did not request this, you can safely ignore this email.</p>
      <p>Salahny Team</p>
    </div>
  `;

  return { text, html };
};

const issueSession = async (user) => {
  const token = generateToken({ id: user._id, role: user.role });
  const refreshToken = generateRefreshToken({ id: user._id, role: user.role });
  const decoded = jwt.decode(refreshToken);

  await RefreshToken.create({
    user: user._id,
    tokenHash: hashToken(refreshToken),
    expiresAt: new Date(decoded.exp * 1000),
  });

  return { token, refreshToken };
};

export const register = asyncHandler(async (req, res) => {
  const { name, email, phone, password, role = 'driver' } = req.body;

  if (!name || !email || !phone || !password) {
    return res.status(400).json({
      success: false,
      message: 'Name, email, phone, and password are required',
    });
  }

  if (!['driver', 'workshop'].includes(role)) {
    return res.status(400).json({
      success: false,
      message: 'Role must be driver or workshop',
    });
  }

  const existingUser = await User.findOne({ email: email.toLowerCase() });

  if (existingUser) {
    return res.status(409).json({
      success: false,
      message: 'User already exists',
    });
  }

  const user = await User.create({
    name,
    email: email.toLowerCase(),
    phone,
    password,
    role,
    accountStatus: 'pending',
    verificationStatus: 'pending_upload',
    aiVerificationStatus: 'pending_upload',
  });

  const { token, refreshToken } = await issueSession(user);

  res.status(201).json({
    success: true,
    message: 'User registered successfully',
    data: {
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
      },
      token,
      refreshToken,
    },
  });
});

export const login = asyncHandler(async (req, res) => {
  const { email, password, expectedRole } = req.body;

  if (!email || !password) {
    return res.status(400).json({
      success: false,
      message: 'Email and password are required',
    });
  }

  if (expectedRole && !['driver', 'workshop', 'admin'].includes(expectedRole)) {
    return res.status(400).json({
      success: false,
      message: 'Invalid login role',
    });
  }

  if (isUnsafeDemoAdminLogin(email, password)) {
    return res.status(403).json({
      success: false,
      message:
        'Default demo admin password is disabled on hosted deployments. Set ADMIN_PASSWORD in Railway and redeploy.',
    });
  }

  if (isDefaultAdminEmail(email)) {
    await ensureAdminUser();
  }

  const user = await User.findOne({ email: email.toLowerCase() }).select(
    '+password',
  );

  if (!user || !(await user.comparePassword(password))) {
    return res.status(401).json({
      success: false,
      message: 'Invalid email or password',
    });
  }

  if (expectedRole && user.role !== expectedRole && user.role !== 'admin') {
    return res.status(403).json({
      success: false,
      message: `This account is registered as ${user.role}. Please login from the ${user.role} dashboard.`,
    });
  }

  if (user.accountStatus === 'suspended') {
    return res.status(403).json({
      success: false,
      message: 'This account is suspended',
    });
  }

  if (user.accountStatus === 'rejected' || user.accountStatus === 'deleted') {
    return res.status(403).json({
      success: false,
      message: 'This account is not available',
    });
  }

  if (user.accountStatus === 'pending') {
    return res.status(403).json({
      success: false,
      message: 'This account is waiting for admin verification',
    });
  }

  const { token, refreshToken } = await issueSession(user);

  res.status(200).json({
    success: true,
    message: 'Login successful',
    data: {
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
      },
      token,
      refreshToken,
    },
  });
});

export const googleLogin = asyncHandler(async (req, res) => {
  const { idToken } = req.body;

  const googleClientIds = (
    process.env.GOOGLE_CLIENT_IDS ||
    process.env.GOOGLE_CLIENT_ID ||
    ''
  )
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);

  if (googleClientIds.length === 0) {
    return res.status(503).json({
      success: false,
      message: 'Google sign-in is not configured',
    });
  }

  if (!idToken) {
    return res.status(400).json({
      success: false,
      message: 'idToken is required',
    });
  }

  const client = new OAuth2Client();
  let payload;

  try {
    const ticket = await client.verifyIdToken({
      idToken,
      audience: googleClientIds,
    });

    payload = ticket.getPayload();
  } catch {
    return res.status(401).json({
      success: false,
      message: 'Google token is invalid',
    });
  }

  const email = payload?.email?.toLowerCase();

  if (!email || payload?.email_verified !== true) {
    return res.status(401).json({
      success: false,
      message: 'Google account email is not verified',
    });
  }

  const user = await User.findOne({ email });

  if (!user) {
    return res.status(404).json({
      success: false,
      message:
        'Please create an account first using Sign Up, then continue with Google.',
    });
  }

  if (!user.googleSubject) {
    user.googleSubject = payload.sub;
    user.authProvider = user.authProvider || 'google';
    user.photoUrl = payload.picture || user.photoUrl;
    await user.save();
  }

  if (user.accountStatus === 'pending') {
    return res.status(403).json({
      success: false,
      message: 'This account is waiting for admin verification.',
    });
  }

  if (user.accountStatus === 'suspended') {
    return res.status(403).json({
      success: false,
      message: 'This account is suspended.',
    });
  }

  if (user.accountStatus === 'rejected' || user.accountStatus === 'deleted') {
    return res.status(403).json({
      success: false,
      message: 'This account is not available.',
    });
  }

  if (user.accountStatus !== 'active') {
    return res.status(403).json({
      success: false,
      message: 'This account is not active.',
    });
  }

  const { token, refreshToken } = await issueSession(user);

  res.status(200).json({
    success: true,
    message: 'Google login successful',
    data: {
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phone: user.phone,
        role: user.role,
        profileCompleted: user.profileCompleted,
        verificationStatus: user.verificationStatus,
        aiVerificationStatus: user.aiVerificationStatus,
      },
      token,
      refreshToken,
    },
  });
});

export const requestPasswordReset = asyncHandler(async (req, res) => {
  const email = req.body.email?.toString().trim().toLowerCase();

  if (!email) {
    return res.status(400).json({
      success: false,
      message: 'Email is required',
    });
  }

  const user = await User.findOne({ email }).select(
    '+passwordResetTokenHash +passwordResetExpiresAt',
  );

  let resetToken;

  if (user && user.accountStatus !== 'deleted') {
    resetToken = crypto.randomBytes(32).toString('hex');
    user.passwordResetTokenHash = hashToken(resetToken);
    user.passwordResetExpiresAt = new Date(Date.now() + 15 * 60 * 1000);
    await user.save();

    const { text, html } = buildPasswordResetEmail({ user, resetToken });

    const emailResult = await sendEmail({
      to: user.email,
      subject: 'Reset your Salahny password',
      text,
      html,
    });

    if (!emailResult.sent) {
      user.passwordResetTokenHash = null;
      user.passwordResetExpiresAt = null;
      await user.save();

      console.error('[auth] Password reset email failed', {
        reason: emailResult.error || emailResult.code || emailResult.reason,
      });

      return res.status(200).json({
        success: true,
        message: 'If this email exists, a reset link has been sent.',
      });
    }
  }

  const data =
    resetToken && process.env.PASSWORD_RESET_RETURN_TOKEN === 'true'
      ? { resetToken }
      : undefined;

  res.status(200).json({
    success: true,
    message: 'If this email exists, a reset link has been sent.',
    data,
  });
});

export const resetPassword = asyncHandler(async (req, res) => {
  const { token, password } = req.body;

  if (!token || !password) {
    return res.status(400).json({
      success: false,
      message: 'token and password are required',
    });
  }

  if (password.length < 8) {
    return res.status(400).json({
      success: false,
      message: 'Password must be at least 8 characters',
    });
  }

  const user = await User.findOne({
    passwordResetTokenHash: hashToken(token),
    passwordResetExpiresAt: { $gt: new Date() },
  }).select('+password +passwordResetTokenHash +passwordResetExpiresAt');

  if (!user) {
    return res.status(400).json({
      success: false,
      message: 'Reset token is invalid or expired',
    });
  }

  user.password = password;
  user.passwordResetTokenHash = null;
  user.passwordResetExpiresAt = null;
  await user.save();

  await RefreshToken.updateMany(
    { user: user._id, revokedAt: null },
    { revokedAt: new Date() },
  );

  res.status(200).json({
    success: true,
    message: 'Password reset successfully',
  });
});

export const refresh = asyncHandler(async (req, res) => {
  const { refreshToken } = req.body;

  if (!refreshToken) {
    return res.status(400).json({
      success: false,
      message: 'refreshToken is required',
    });
  }

  let decoded;

  try {
    decoded = jwt.verify(
      refreshToken,
      process.env.JWT_REFRESH_SECRET || process.env.JWT_SECRET,
    );
  } catch {
    return res.status(401).json({
      success: false,
      message: 'Refresh token invalid',
    });
  }

  const stored = await RefreshToken.findOne({
    tokenHash: hashToken(refreshToken),
    revokedAt: null,
  });

  const user = await User.findById(decoded.id);

  if (!stored || !user || user.accountStatus !== 'active') {
    return res.status(401).json({
      success: false,
      message: 'Refresh token unavailable',
    });
  }

  stored.revokedAt = new Date();
  await stored.save();

  const session = await issueSession(user);

  res.status(200).json({
    success: true,
    data: session,
  });
});

export const logout = asyncHandler(async (req, res) => {
  const { refreshToken } = req.body;

  if (refreshToken) {
    await RefreshToken.findOneAndUpdate(
      { tokenHash: hashToken(refreshToken), revokedAt: null },
      { revokedAt: new Date() },
    );
  }

  res.status(200).json({
    success: true,
    message: 'Logged out',
  });
});