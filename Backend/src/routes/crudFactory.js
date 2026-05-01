const express = require('express');
const { auth, requireRole } = require('../middleware/auth');

const ownedQuery = (req, baseQuery = {}) => {
  if (req.user.role === 'admin') return baseQuery;
  return { ...baseQuery, user: req.user._id };
};

const crudRouter = (Model, options = {}) => {
  const router = express.Router();
  const {
    authRequired = true,
    createRoles = ['driver', 'workshop', 'admin'],
    updateRoles = ['driver', 'workshop', 'admin'],
    deleteRoles = ['admin'],
    populate = [],
    ownerField = 'user',
    publicRead = false,
  } = options;

  const maybeAuth = authRequired ? [auth] : [];
  const applyPopulate = (query) => populate.reduce((q, field) => q.populate(field), query);

  router.get('/', ...(publicRead ? [] : maybeAuth), async (req, res) => {
    try {
      const filter = {};
      if (req.query.status) filter.status = req.query.status;
      if (req.query.category) filter.category = req.query.category;
      if (req.query.workshop) filter.workshop = req.query.workshop;
      if (authRequired && req.user && options.scopeToOwner) {
        Object.assign(filter, ownedQuery(req, {}));
      }
      const docs = await applyPopulate(Model.find(filter)).sort({ createdAt: -1 });
      return res.json(docs);
    } catch (err) {
      return res.status(500).json({ detail: err.message });
    }
  });

  router.post('/', ...maybeAuth, requireRole(createRoles), async (req, res) => {
    try {
      const payload = { ...req.body };
      if (authRequired && ownerField && !payload[ownerField]) payload[ownerField] = req.user._id;
      const doc = await Model.create(payload);
      return res.status(201).json(doc);
    } catch (err) {
      return res.status(400).json({ detail: err.message });
    }
  });

  router.get('/:id', ...(publicRead ? [] : maybeAuth), async (req, res) => {
    try {
      const doc = await applyPopulate(Model.findById(req.params.id));
      if (!doc) return res.status(404).json({ detail: 'Resource not found' });
      return res.json(doc);
    } catch {
      return res.status(400).json({ detail: 'Invalid resource ID' });
    }
  });

  router.put('/:id', ...maybeAuth, requireRole(updateRoles), async (req, res) => {
    try {
      const doc = await Model.findById(req.params.id);
      if (!doc) return res.status(404).json({ detail: 'Resource not found' });

      if (ownerField && req.user.role !== 'admin' && doc[ownerField]?.toString() !== req.user._id.toString()) {
        return res.status(403).json({ detail: 'Access denied' });
      }

      Object.assign(doc, req.body);
      await doc.save();
      return res.json(doc);
    } catch (err) {
      return res.status(400).json({ detail: err.message });
    }
  });

  router.delete('/:id', ...maybeAuth, requireRole(deleteRoles), async (req, res) => {
    try {
      const doc = await Model.findByIdAndDelete(req.params.id);
      if (!doc) return res.status(404).json({ detail: 'Resource not found' });
      return res.json({ message: 'Deleted successfully' });
    } catch {
      return res.status(400).json({ detail: 'Invalid resource ID' });
    }
  });

  return router;
};

module.exports = crudRouter;
