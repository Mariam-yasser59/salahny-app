import User from '../models/User.js';
import PackagePurchase from '../models/PackagePurchase.js';
import Vehicle from '../models/Vehicle.js';
import Booking from '../models/Booking.js';
import asyncHandler from '../utils/asyncHandler.js';

export const getCurrentUser = asyncHandler(async (req, res) => {
  const activeSubscription = await PackagePurchase.findOne({
    user: req.user._id,
    status: { $in: ['paid', 'success'] },
    endsAt: { $gt: new Date() },
  }).sort({ endsAt: -1 });

  const vehicleCount = await Vehicle.countDocuments({ owner: req.user._id });
  const totalBookings = await Booking.countDocuments({ user: req.user._id });

  res.status(200).json({
    success: true,
    data: {
      ...req.user.toObject(),
      vehicleCount,
      totalBookings,
      activeSubscription: activeSubscription
        ? {
            packageName: activeSubscription.packageName,
            startsAt: activeSubscription.startsAt,
            endsAt: activeSubscription.endsAt,
            remainingDays: Math.ceil(
              (activeSubscription.endsAt.getTime() - Date.now()) /
                (24 * 60 * 60 * 1000),
            ),
          }
        : null,
    },
  });
});

export const updateCurrentUser = asyncHandler(async (req, res) => {
  const { name, email, phone } = req.body;

  if (!name || !email || !phone) {
    return res.status(400).json({
      success: false,
      message: 'Name, email, and phone are required',
    });
  }

  const normalizedEmail = email.toString().trim().toLowerCase();

  const duplicate = await User.findOne({
    email: normalizedEmail,
    _id: { $ne: req.user._id },
  });

  if (duplicate) {
    return res.status(409).json({
      success: false,
      message: 'Email is already in use',
    });
  }

  req.user.name = name.toString().trim();
  req.user.email = normalizedEmail;
  req.user.phone = phone.toString().trim();

  await req.user.save();

  res.status(200).json({
    success: true,
    message: 'Profile updated successfully',
    data: req.user,
  });
});

export const deleteCurrentUser = asyncHandler(async (req, res) => {
  const userId = req.user._id;

  await PackagePurchase.deleteMany({ user: userId });
  await Vehicle.deleteMany({ owner: userId });
  await Booking.deleteMany({ user: userId });
  await User.findByIdAndDelete(userId);

  res.status(200).json({
    success: true,
    message: 'Account deleted successfully',
  });
});

export const getUsers = asyncHandler(async (req, res) => {
  const filter = req.query.role ? { role: req.query.role } : {};
  const users = await User.find(filter).select('-password');

  res.status(200).json({
    success: true,
    count: users.length,
    data: users,
  });
});

export const getUserById = asyncHandler(async (req, res) => {
  const user = await User.findById(req.params.id).select('-password');

  if (!user) {
    return res.status(404).json({
      success: false,
      message: 'User not found',
    });
  }

  res.status(200).json({
    success: true,
    data: user,
  });
});