const express = require('express');
const {
  createWorkshop,
  getWorkshopById,
  getWorkshops,
  updateWorkshop,
} = require('../controllers/workshopController');
const { auth, requireRole } = require('../middleware/auth');

const router = express.Router();

router.get('/', getWorkshops);
router.post('/', auth, requireRole('workshop', 'admin'), createWorkshop);
router.get('/:id', getWorkshopById);
router.put('/:id', auth, requireRole('workshop', 'admin'), updateWorkshop);

module.exports = router;
