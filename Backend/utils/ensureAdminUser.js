import User from '../models/User.js';

const adminEmail = process.env.ADMIN_EMAIL || 'admin@salahny.com';
const demoAdminPassword = 'admin123';

const isHostedProductionLike = () =>
  process.env.NODE_ENV === 'production' ||
  Boolean(process.env.RAILWAY_ENVIRONMENT || process.env.RAILWAY_PROJECT_ID);

const allowDemoAdmin = () =>
  !isHostedProductionLike() && process.env.ALLOW_DEMO_ADMIN !== 'false';

const adminPassword = process.env.ADMIN_PASSWORD || (allowDemoAdmin() ? demoAdminPassword : '');

export const ensureAdminUser = async () => {
  let admin = await User.findOne({ email: adminEmail }).select('+password');

  if (!admin) {
    if (!adminPassword) {
      throw new Error('ADMIN_PASSWORD must be configured before creating the first admin');
    }
    admin = await User.create({
      name: 'Salahny Super Admin',
      email: adminEmail,
      phone: '01000000000',
      password: adminPassword,
      role: 'admin',
      accountStatus: 'active',
    });
    admin = await User.findById(admin._id).select('+password');
  } else if (process.env.ADMIN_PASSWORD) {
    const stillUsingDemoPassword = await admin.comparePassword(demoAdminPassword);
    if (stillUsingDemoPassword && !(await admin.comparePassword(process.env.ADMIN_PASSWORD))) {
      admin.password = process.env.ADMIN_PASSWORD;
      admin.accountStatus = 'active';
      await admin.save();
      admin = await User.findById(admin._id).select('+password');
    }
  }

  return admin;
};

export const isDefaultAdminEmail = (email = '') =>
  email.trim().toLowerCase() == adminEmail;

export const isUnsafeDemoAdminLogin = (email = '', password = '') =>
  isDefaultAdminEmail(email) &&
  password === demoAdminPassword &&
  isHostedProductionLike() &&
  process.env.ALLOW_DEMO_ADMIN !== 'true';
