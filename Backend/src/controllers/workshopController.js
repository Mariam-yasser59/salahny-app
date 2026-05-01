const Workshop = require('../models/Workshop');

const createWorkshop = async (req, res) => {
  try {
    const owner = req.user.role === 'admin' ? req.body.owner || req.user._id : req.user._id;
    const workshop = await Workshop.create({
      name: req.body.name,
      location: req.body.location,
      services: req.body.services || [],
      prices: req.body.prices || {},
      owner,
    });

    return res.status(201).json(workshop);
  } catch (err) {
    return res.status(500).json({ detail: err.message });
  }
};

const getWorkshops = async (req, res) => {
  try {
    const query = {};
    if (req.query.service) query.services = new RegExp(req.query.service, 'i');
    if (req.query.location) query.location = new RegExp(req.query.location, 'i');

    const workshops = await Workshop.find(query)
      .populate('owner', 'name email role phone')
      .sort({ createdAt: -1 });

    return res.json(workshops);
  } catch (err) {
    return res.status(500).json({ detail: err.message });
  }
};

const getWorkshopById = async (req, res) => {
  try {
    const workshop = await Workshop.findById(req.params.id).populate('owner', 'name email role phone');
    if (!workshop) {
      return res.status(404).json({ detail: 'Workshop not found' });
    }
    return res.json(workshop);
  } catch {
    return res.status(400).json({ detail: 'Invalid workshop ID' });
  }
};

const updateWorkshop = async (req, res) => {
  try {
    const workshop = await Workshop.findById(req.params.id);
    if (!workshop) {
      return res.status(404).json({ detail: 'Workshop not found' });
    }

    const isOwner = workshop.owner.toString() === req.user._id.toString();
    if (!isOwner && req.user.role !== 'admin') {
      return res.status(403).json({ detail: 'Access denied' });
    }

    const allowed = ['name', 'location', 'services', 'prices'];
    allowed.forEach((field) => {
      if (req.body[field] !== undefined) workshop[field] = req.body[field];
    });

    await workshop.save();
    return res.json(workshop);
  } catch (err) {
    return res.status(500).json({ detail: err.message });
  }
};

module.exports = {
  createWorkshop,
  getWorkshops,
  getWorkshopById,
  updateWorkshop,
};
