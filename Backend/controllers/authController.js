import User from '../models/User.js';
import { ensureAdminUser, isDefaultAdminEmail } from '../utils/ensureAdminUser.js';
import asyncHandler from '../utils/asyncHandler.js';
import generateToken from '../utils/generateToken.js';

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
    email,
    phone,
    password,
    role,
  });

  const token = generateToken({ id: user._id, role: user.role });

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
    },
  });
});

export const login = asyncHandler(async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({
      success: false,
      message: 'Email and password are required',
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

  const token = generateToken({ id: user._id, role: user.role });

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
    },
  });
});
