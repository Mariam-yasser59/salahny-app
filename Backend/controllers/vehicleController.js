import Vehicle from '../models/Vehicle.js';
import asyncHandler from '../utils/asyncHandler.js';

const toPayload = (doc) => ({
  id: doc._id.toString(),
  make: doc.make,
  model: doc.model,
  year: doc.year,
  plate: doc.plate,
  color: doc.color,
  fuel: doc.fuel,
  mileage: doc.mileage,
  health: doc.health,
  createdAt: doc.createdAt,
});

export const getVehicles = asyncHandler(async (req, res) => {
  const vehicles = await Vehicle.find({ owner: req.user._id }).sort({ createdAt: -1 });
  res.status(200).json({
    success: true,
    data: vehicles.map(toPayload),
  });
});

export const getVehicleById = asyncHandler(async (req, res) => {
  const vehicle = await Vehicle.findOne({ _id: req.params.id, owner: req.user._id });
  if (!vehicle) {
    return res.status(404).json({ success: false, message: 'Vehicle not found' });
  }
  res.status(200).json({ success: true, data: toPayload(vehicle) });
});

export const createVehicle = asyncHandler(async (req, res) => {
  const { make, model, year, plate, color = 'White', fuel = 'Gasoline', mileage = 0 } = req.body;

  if (!make || !model || !year || !plate) {
    return res.status(400).json({
      success: false,
      message: 'make, model, year, and plate are required',
    });
  }

  const vehicle = await Vehicle.create({
    owner: req.user._id,
    make,
    model,
    year: year.toString(),
    plate,
    color,
    fuel,
    mileage,
    health: 100,
  });

  res.status(201).json({ success: true, data: toPayload(vehicle) });
});

export const updateVehicle = asyncHandler(async (req, res) => {
  const vehicle = await Vehicle.findOne({ _id: req.params.id, owner: req.user._id });
  if (!vehicle) {
    return res.status(404).json({ success: false, message: 'Vehicle not found' });
  }

  const fields = ['make', 'model', 'year', 'plate', 'color', 'fuel', 'mileage', 'health'];
  fields.forEach((f) => {
    if (req.body[f] !== undefined) vehicle[f] = req.body[f];
  });

  await vehicle.save();
  res.status(200).json({ success: true, data: toPayload(vehicle) });
});

export const deleteVehicle = asyncHandler(async (req, res) => {
  const vehicle = await Vehicle.findOneAndDelete({ _id: req.params.id, owner: req.user._id });
  if (!vehicle) {
    return res.status(404).json({ success: false, message: 'Vehicle not found' });
  }
  res.status(200).json({ success: true, message: 'Vehicle deleted' });
});
