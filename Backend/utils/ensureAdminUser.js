import User from '../models/User.js';

const adminEmail = 'admin@salahny.com';
const adminPassword = process.env.ADMIN_PASSWORD || 'admin123';

export const ensureAdminUser = async () => {
  let admin = await User.findOne({ email: adminEmail }).select('+password');

  if (!admin) {
    admin = await User.create({
      name: 'Salahny Super Admin',
      email: adminEmail,
      phone: '01000000000',
      password: adminPassword,
      role: 'admin',
      accountStatus: 'active',
    });
    admin = await User.findById(admin._id).select('+password');
  }

  return admin;
};

export const isDefaultAdminEmail = (email = '') =>
  email.trim().toLowerCase() == adminEmail;
