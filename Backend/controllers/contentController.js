import AdminSetting from '../models/AdminSetting.js';
import User from '../models/User.js';
import asyncHandler from '../utils/asyncHandler.js';
import { logActivity } from '../utils/activityLogger.js';

const defaultSettings = {
  key: 'platform',
  privacyPolicy:
    'Salahny keeps booking, workshop, and payment metadata secure and visible only to authorized roles.',
  aboutContent:
    'Salahny connects drivers with trusted workshops and supervises the whole service flow as a managed platform.',
  announcementTitle: 'Weekend maintenance push',
  announcementBody: 'Promote AC and brake services across all active workshops.',
  notificationsEnabled: true,
};

const ensureSettings = async () => {
  let settings = await AdminSetting.findOne({ key: 'platform' });
  if (!settings) {
    settings = await AdminSetting.create(defaultSettings);
  }
  return settings;
};

export const getPublicContent = asyncHandler(async (_req, res) => {
  const settings = await ensureSettings();
  res.status(200).json({
    success: true,
    data: {
      privacyPolicy: settings.privacyPolicy,
      aboutContent: settings.aboutContent,
      announcementTitle: settings.announcementTitle,
      announcementBody: settings.announcementBody,
      notificationsEnabled: settings.notificationsEnabled,
    },
  });
});

export const getAdminSettings = asyncHandler(async (_req, res) => {
  const settings = await ensureSettings();
  res.status(200).json({ success: true, data: settings });
});

export const updateAdminSettings = asyncHandler(async (req, res) => {
  const settings = await ensureSettings();
  const {
    privacyPolicy,
    aboutContent,
    announcementTitle,
    announcementBody,
    notificationsEnabled,
  } = req.body;

  if (privacyPolicy !== undefined) settings.privacyPolicy = privacyPolicy;
  if (aboutContent !== undefined) settings.aboutContent = aboutContent;
  if (announcementTitle !== undefined) settings.announcementTitle = announcementTitle;
  if (announcementBody !== undefined) settings.announcementBody = announcementBody;
  if (notificationsEnabled !== undefined) {
    settings.notificationsEnabled = notificationsEnabled;
  }

  await settings.save();
  await logActivity({
    actor: req.user.name,
    actorRole: req.user.role,
    action: 'Settings updated',
    target: 'Platform settings',
    details: 'Admin settings and public content were updated.',
  });

  res.status(200).json({ success: true, data: settings });
});

export const updateAdminPassword = asyncHandler(async (req, res) => {
  const { password } = req.body;
  if (!password || password.trim().length < 6) {
    return res.status(400).json({
      success: false,
      message: 'Use at least 6 characters for the admin password',
    });
  }

  const admin = await User.findById(req.user._id).select('+password');
  admin.password = password.trim();
  await admin.save();

  await logActivity({
    actor: req.user.name,
    actorRole: req.user.role,
    action: 'Admin password changed',
    target: req.user.email,
    details: 'Private admin credentials were updated.',
  });

  res.status(200).json({ success: true, message: 'Admin password updated' });
});
