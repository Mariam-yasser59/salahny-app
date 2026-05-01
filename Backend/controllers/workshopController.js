import User from '../models/User.js';
import Workshop from '../models/Workshop.js';
import asyncHandler from '../utils/asyncHandler.js';

export const createWorkshop = asyncHandler(async (req, res) => {
  const {
    name,
    location,
    services = [],
    prices = {},
    owner,
    rating = 4.8,
    isVerified = false,
    accountStatus = 'active',
  } = req.body;

  if (!name || !location) {
    return res.status(400).json({
      success: false,
      message: 'Name and location are required',
    });
  }

  const ownerId = req.user.role === 'admin' && owner ? owner : req.user._id;
  const ownerUser = await User.findById(ownerId);

  if (!ownerUser) {
    return res.status(404).json({
      success: false,
      message: 'Owner user not found',
    });
  }

  const workshop = await Workshop.create({
    name,
    location,
    services,
    prices,
    owner: ownerUser._id,
    rating,
    isVerified,
    accountStatus,
  });

  const populatedWorkshop = await workshop.populate(
    'owner',
    'name email phone role',
  );

  res.status(201).json({
    success: true,
    message: 'Workshop created successfully',
    data: populatedWorkshop,
  });
});

export const getWorkshops = asyncHandler(async (_req, res) => {
  const workshops = await Workshop.find().populate(
    'owner',
    'name email phone role',
  );

  res.status(200).json({
    success: true,
    count: workshops.length,
    data: workshops,
  });
});

export const getWorkshopById = asyncHandler(async (req, res) => {
  const workshop = await Workshop.findById(req.params.id).populate(
    'owner',
    'name email phone role',
  );

  if (!workshop) {
    return res.status(404).json({
      success: false,
      message: 'Workshop not found',
    });
  }

  res.status(200).json({
    success: true,
    data: workshop,
  });
});

export const updateWorkshop = asyncHandler(async (req, res) => {
  const workshop = await Workshop.findById(req.params.id);

  if (!workshop) {
    return res.status(404).json({
      success: false,
      message: 'Workshop not found',
    });
  }

  const canManage =
    req.user.role === 'admin' || workshop.owner.toString() === req.user._id.toString();

  if (!canManage) {
    return res.status(403).json({
      success: false,
      message: 'You cannot update this workshop',
    });
  }

  const { name, location, services, prices, rating, isVerified, accountStatus } = req.body;

  if (name !== undefined) workshop.name = name;
  if (location !== undefined) workshop.location = location;
  if (services !== undefined) workshop.services = services;
  if (prices !== undefined) workshop.prices = prices;
  if (rating !== undefined) workshop.rating = rating;
  if (isVerified !== undefined) workshop.isVerified = isVerified;
  if (accountStatus !== undefined) workshop.accountStatus = accountStatus;

  await workshop.save();

  const populatedWorkshop = await workshop.populate(
    'owner',
    'name email phone role',
  );

  res.status(200).json({
    success: true,
    message: 'Workshop updated successfully',
    data: populatedWorkshop,
  });
});

export const deleteWorkshop = asyncHandler(async (req, res) => {
  const workshop = await Workshop.findById(req.params.id);

  if (!workshop) {
    return res.status(404).json({
      success: false,
      message: 'Workshop not found',
    });
  }

  const canManage =
    req.user.role === 'admin' || workshop.owner.toString() === req.user._id.toString();

  if (!canManage) {
    return res.status(403).json({
      success: false,
      message: 'You cannot delete this workshop',
    });
  }

  await workshop.deleteOne();

  res.status(200).json({
    success: true,
    message: 'Workshop deleted successfully',
  });
});
