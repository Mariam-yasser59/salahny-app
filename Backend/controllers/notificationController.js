import Notification from '../models/Notification.js';
import AdminSetting from '../models/AdminSetting.js';
import asyncHandler from '../utils/asyncHandler.js';

export const createNotification = async ({
  userId = null,
  title,
  body,
  type = 'system',
  isGlobal = false,
}) => {
  return Notification.create({
    user: userId,
    title,
    body,
    type,
    isGlobal,
  });
};

export const getNotifications = asyncHandler(async (req, res) => {
  const settings = await AdminSetting.findOne({ key: 'platform' });
  const notifications = await Notification.find({
    $or: [{ user: req.user._id }, { isGlobal: true }],
  }).sort({ createdAt: -1 });

  if (
    settings?.notificationsEnabled &&
    settings.announcementTitle &&
    settings.announcementBody
  ) {
    notifications.unshift({
      _id: 'announcement',
      title: settings.announcementTitle,
      body: settings.announcementBody,
      type: 'promo',
      isRead: false,
      createdAt: settings.updatedAt,
    });
  }

  res.status(200).json({
    success: true,
    data: notifications.map((item) => ({
      id: item._id?.toString?.() ?? 'announcement',
      title: item.title,
      body: item.body,
      type: item.type,
      isRead: item.isRead ?? false,
      time: item.createdAt,
    })),
  });
});

export const markNotificationRead = asyncHandler(async (req, res) => {
  const notification = await Notification.findById(req.params.id);
  if (!notification) {
    return res.status(404).json({ success: false, message: 'Notification not found' });
  }
  if (
    notification.user &&
    notification.user.toString() !== req.user._id.toString() &&
    req.user.role !== 'admin'
  ) {
    return res.status(403).json({ success: false, message: 'Access denied' });
  }
  notification.isRead = true;
  await notification.save();
  res.status(200).json({ success: true, message: 'Notification marked as read' });
});
