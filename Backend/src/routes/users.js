const express = require('express');
const {
  getProfile,
  getUserById,
  getUsers,
  updatePassword,
  updateProfile,
} = require('../controllers/userController');
const { auth, requireRole } = require('../middleware/auth');

const router = express.Router();

router.get('/', auth, requireRole('admin'), getUsers);
router.get('/me', auth, getProfile);
router.get('/profile', auth, getProfile);
router.put('/profile', auth, updateProfile);
router.put('/password', auth, updatePassword);
router.get('/:id', auth, getUserById);

module.exports = router;
