import jwt from 'jsonwebtoken';

import User from '../models/User.js';

export const protect = async (req, res, next) => {
  try {
    const authHeader =
      req.headers.authorization ||
      (req.query.token ? `Bearer ${req.query.token}` : undefined);

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'Not authorized, token missing',
      });
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(decoded.id).select('-password');

    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Not authorized, user not found',
      });
    }

    req.user = user;
    const pendingAllowed =
      req.originalUrl.startsWith('/api/documents') ||
      req.originalUrl.startsWith('/api/verification/upload-document') ||
      (user.role === 'workshop' &&
        req.method === 'POST' &&
        req.originalUrl.startsWith('/api/workshops'));
    if (user.accountStatus === 'pending' && !pendingAllowed) {
      return res.status(403).json({
        success: false,
        message: 'This account is waiting for admin verification',
      });
    }
    next();
  } catch (error) {
    return res.status(401).json({
      success: false,
      message: 'Not authorized, token invalid',
    });
  }
};

export const optionalProtect = async (req, _res, next) => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next();
  }

  try {
    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(decoded.id).select('-password');
    if (user) {
      req.user = user;
    }
  } catch {
    // Public endpoints remain public when no valid token is supplied.
  }

  next();
};
