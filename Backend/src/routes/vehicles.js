const express = require('express');
const Vehicle = require('../models/Vehicle');
const { auth } = require('../middleware/auth');

const router = express.Router();

// GET /vehicles
router.get('/', auth, async (req, res) => {
  const vehicles = await Vehicle.find({ ownerId: req.user._id.toString() });
  res.json(vehicles);
});

// POST /vehicles
router.post('/', auth, async (req, res) => {
  try {
    const { make, model, year, plate, color, fuelType, mileage } = req.body;
    const vehicle = await Vehicle.create({
      ownerId: req.user._id.toString(),
      make, model, year, plate, color, fuelType, mileage,
    });
    res.status(201).json(vehicle);
  } catch (err) {
    res.status(500).json({ detail: err.message });
  }
});

// GET /vehicles/:id
router.get('/:id', auth, async (req, res) => {
  try {
    const vehicle = await Vehicle.findOne({ _id: req.params.id, ownerId: req.user._id.toString() });
    if (!vehicle) return res.status(404).json({ detail: 'Vehicle not found' });
    res.json(vehicle);
  } catch {
    res.status(400).json({ detail: 'Invalid vehicle ID' });
  }
});

// PUT /vehicles/:id
router.put('/:id', auth, async (req, res) => {
  try {
    const vehicle = await Vehicle.findOneAndUpdate(
      { _id: req.params.id, ownerId: req.user._id.toString() },
      req.body,
      { new: true },
    );
    if (!vehicle) return res.status(404).json({ detail: 'Vehicle not found' });
    res.json(vehicle);
  } catch {
    res.status(400).json({ detail: 'Invalid vehicle ID' });
  }
});

// DELETE /vehicles/:id
router.delete('/:id', auth, async (req, res) => {
  try {
    const result = await Vehicle.findOneAndDelete({ _id: req.params.id, ownerId: req.user._id.toString() });
    if (!result) return res.status(404).json({ detail: 'Vehicle not found' });
    res.status(204).send();
  } catch {
    res.status(400).json({ detail: 'Invalid vehicle ID' });
  }
});

module.exports = router;
