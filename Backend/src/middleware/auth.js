const jwt = require('jsonwebtoken');
const User = require('../models/User');

const auth = async (req, res, next) => {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    return res.status(401).json({ detail: 'No token provided' });
  }
  const token = header.split(' ')[1];
  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(payload.sub);
    if (!user || !user.isActive) {
      return res.status(401).json({ detail: 'User not found or deactivated' });
    }
    req.user = user;
    next();
  } catch {
    return res.status(401).json({ detail: 'Invalid or expired token' });
  }
};

const normalizeRole = (role) => (role === 'user' ? 'driver' : role);

const requireRole = (...roles) => (req, res, next) => {
  const allowedRoles = roles.flat().map(normalizeRole);
  if (!allowedRoles.includes(req.user.role)) {
    return res.status(403).json({ detail: `${allowedRoles.join(' or ')} access only` });
  }
  next();
};

module.exports = { auth, requireRole };
