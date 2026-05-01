const User = require('../models/User');

const getProfile = (req, res) => res.json(req.user);

const getUsers = async (_req, res) => {
  const users = await User.find().sort({ createdAt: -1 });
  return res.json(users);
};

const updateProfile = async (req, res) => {
  try {
    const allowed = ['name', 'phone', 'email', 'workshopName', 'address', 'specialty', 'isOpen'];
    const updates = Object.fromEntries(
      Object.entries(req.body).filter(([key]) => allowed.includes(key)),
    );

    if (!Object.keys(updates).length) {
      return res.status(400).json({ detail: 'No valid fields to update' });
    }

    const updated = await User.findByIdAndUpdate(req.user._id, updates, { new: true });
    return res.json(updated);
  } catch (err) {
    return res.status(500).json({ detail: err.message });
  }
};

const updatePassword = async (req, res) => {
  try {
    const { currentPassword, newPassword } = req.body;
    const user = await User.findById(req.user._id).select('+password');

    if (!(await user.comparePassword(currentPassword))) {
      return res.status(400).json({ detail: 'Current password is incorrect' });
    }

    user.password = newPassword;
    await user.save();
    return res.json({ message: 'Password updated successfully' });
  } catch (err) {
    return res.status(500).json({ detail: err.message });
  }
};

const getUserById = async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({ detail: 'User not found' });
    }
    return res.json(user);
  } catch {
    return res.status(400).json({ detail: 'Invalid user ID' });
  }
};

module.exports = {
  getProfile,
  getUsers,
  updateProfile,
  updatePassword,
  getUserById,
};
