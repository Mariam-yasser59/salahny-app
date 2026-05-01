const express = require('express');
const {
  createBooking,
  getBookingById,
  getBookings,
  updateBookingStatus,
} = require('../controllers/bookingController');
const { auth, requireRole } = require('../middleware/auth');

const router = express.Router();

router.get('/', auth, getBookings);
router.post('/', auth, requireRole('driver', 'user'), createBooking);
router.get('/:id', auth, getBookingById);
router.put('/:id/status', auth, updateBookingStatus);

module.exports = router;
