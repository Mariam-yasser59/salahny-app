const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const DriverProfile = require('../models/DriverProfile');
const Admin = require('../models/Admin');

const createToken = (userId, type = 'access') => {
  const defaultExpiry = type === 'refresh' ? '30d' : '7d';
  const expiresIn = type === 'refresh'
    ? process.env.JWT_REFRESH_EXPIRES_IN || defaultExpiry
    : process.env.JWT_EXPIRES_IN || defaultExpiry;

  return jwt.sign({ sub: userId, type }, process.env.JWT_SECRET, { expiresIn });
};

const serializeUser = (user) => ({
  id: user._id.toString(),
  name: user.name,
  email: user.email,
  role: user.role,
});

const register = async (req, res) => {
  try {
    const { name, email, phone, password, role = 'driver', workshopName, address, specialty } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ detail: 'Name, email, and password are required' });
    }
    if (!['driver', 'workshop', 'admin'].includes(role)) {
      return res.status(400).json({ detail: "Role must be 'driver', 'workshop', or 'admin'" });
    }
    if (await User.findOne({ email })) {
      return res.status(400).json({ detail: 'Email already registered' });
    }

    const user = await User.create({
      name,
      email,
      phone,
      password,
      role,
      ...(role === 'workshop' && {
        workshopName: workshopName || name,
        address: address || '',
        specialty: specialty || 'General',
        isOpen: true,
      }),
    });

    if (role === 'driver') {
      await DriverProfile.create({ user: user._id, phone, status: 'active' });
    }
    if (role === 'admin') {
      await Admin.create({ user: user._id, permissions: ['all'], status: 'active' });
    }

    const userId = user._id.toString();
    return res.status(201).json({
      accessToken: createToken(userId),
      refreshToken: createToken(userId, 'refresh'),
      tokenType: 'bearer',
      user: serializeUser(user),
    });
  } catch (err) {
    return res.status(500).json({ detail: err.message });
  }
};

const login = async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email }).select('+password');

    if (!user || !(await user.comparePassword(password))) {
      return res.status(401).json({ detail: 'Invalid email or password' });
    }
    if (!user.isActive) {
      return res.status(403).json({ detail: 'Account deactivated' });
    }

    const userId = user._id.toString();
    return res.json({
      accessToken: createToken(userId),
      refreshToken: createToken(userId, 'refresh'),
      tokenType: 'bearer',
      user: serializeUser(user),
    });
  } catch (err) {
    return res.status(500).json({ detail: err.message });
  }
};

const refresh = (req, res) => {
  try {
    const payload = jwt.verify(req.body.refreshToken, process.env.JWT_SECRET);
    if (payload.type !== 'refresh') {
      return res.status(401).json({ detail: 'Invalid token type' });
    }
    return res.json({ accessToken: createToken(payload.sub), tokenType: 'bearer' });
  } catch {
    return res.status(401).json({ detail: 'Invalid or expired refresh token' });
  }
};

const logout = (_req, res) => res.json({ message: 'Logged out successfully' });

const sendOtp = (req, res) => {
  const otp = Math.floor(100000 + Math.random() * 900000).toString();
  console.log(`[OTP] ${req.body.phone} -> ${otp}`);
  return res.json({ message: 'OTP sent', devOtp: otp });
};

const verifyOtp = async (req, res) => {
  await User.findOneAndUpdate({ phone: req.body.phone }, { isVerified: true });
  return res.json({ message: 'Phone verified successfully' });
};

const forgotPassword = (req, res) => {
  const token = crypto.randomBytes(32).toString('hex');
  console.log(`[RESET] ${req.body.email} -> token: ${token}`);
  return res.json({ message: 'If the email exists, a reset link has been sent', devToken: token });
};

const resetPassword = async (req, res) => {
  try {
    const { email, newPassword } = req.body;
    const user = await User.findOne({ email }).select('+password');
    if (!user) {
      return res.status(404).json({ detail: 'User not found' });
    }

    user.password = newPassword;
    await user.save();
    return res.json({ message: 'Password reset successfully' });
  } catch (err) {
    return res.status(500).json({ detail: err.message });
  }
};

module.exports = {
  register,
  login,
  refresh,
  logout,
  sendOtp,
  verifyOtp,
  forgotPassword,
  resetPassword,
};
