const express = require('express');
const Subscription = require('../models/Subscription');
const ServicePackage = require('../models/ServicePackage');
const crudRouter = require('./crudFactory');
const { auth } = require('../middleware/auth');

const router = express.Router();
const packageCrud = crudRouter(ServicePackage, {
  createRoles: ['admin'],
  updateRoles: ['admin'],
  deleteRoles: ['admin'],
  ownerField: null,
});

router.get('/subscriptions/active', auth, async (req, res) => {
  const sub = await Subscription.findOne({
    userId: req.user._id.toString(),
    status: 'active',
    expiresAt: { $gt: new Date() },
  }).sort({ createdAt: -1 });
  return res.json({ subscription: sub || null });
});

router.post('/:id/subscribe', auth, async (req, res) => {
  try {
    const pkg = await ServicePackage.findById(req.params.id);
    if (!pkg) return res.status(404).json({ detail: 'Package not found' });

    const expiresAt = new Date();
    expiresAt.setMonth(expiresAt.getMonth() + pkg.durationMonths);

    const sub = await Subscription.create({
      userId: req.user._id.toString(),
      packageId: pkg._id.toString(),
      packageName: pkg.name,
      price: pkg.price,
      paymentMethod: req.body.paymentMethod || 'card',
      status: 'active',
      expiresAt,
    });

    return res.status(201).json(sub);
  } catch (err) {
    return res.status(500).json({ detail: err.message });
  }
});

router.use('/', packageCrud);

module.exports = router;
