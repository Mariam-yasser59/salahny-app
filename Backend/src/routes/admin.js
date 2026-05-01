const express = require('express');
const User = require('../models/User');
const Workshop = require('../models/Workshop');
const Booking = require('../models/Booking');
const Service = require('../models/Service');
const ServicePackage = require('../models/ServicePackage');
const EmergencyRequest = require('../models/EmergencyRequest');
const { auth, requireRole } = require('../middleware/auth');

const router = express.Router();

router.use(auth, requireRole('admin'));

router.get('/dashboard', async (_req, res) => {
  const [
    users,
    drivers,
    workshops,
    bookings,
    services,
    packagesCount,
    emergencyRequests,
  ] = await Promise.all([
    User.countDocuments(),
    User.countDocuments({ role: 'driver' }),
    Workshop.countDocuments(),
    Booking.countDocuments(),
    Service.countDocuments(),
    ServicePackage.countDocuments(),
    EmergencyRequest.countDocuments(),
  ]);

  return res.json({
    users,
    drivers,
    workshops,
    bookings,
    services,
    packages: packagesCount,
    emergencyRequests,
  });
});

router.get('/users', async (_req, res) => res.json(await User.find().sort({ createdAt: -1 })));
router.get('/workshops', async (_req, res) => res.json(await Workshop.find().populate('owner', 'name email role').sort({ createdAt: -1 })));
router.get('/bookings', async (_req, res) => res.json(await Booking.find().populate('user workshop').sort({ createdAt: -1 })));

router.put('/users/:id/status', async (req, res) => {
  const user = await User.findByIdAndUpdate(req.params.id, { isActive: req.body.isActive }, { new: true });
  if (!user) return res.status(404).json({ detail: 'User not found' });
  return res.json(user);
});

module.exports = router;
