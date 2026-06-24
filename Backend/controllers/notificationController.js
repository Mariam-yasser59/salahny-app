import Notification from '../models/Notification.js';
import AdminSetting from '../models/AdminSetting.js';
import User from '../models/User.js';
import asyncHandler from '../utils/asyncHandler.js';
import { emitNotification } from '../services/realtimeService.js';
import { sendPushNotificationToUser } from '../services/pushNotificationService.js';

export const createNotification = async ({
  userId = null,
  recipient = null,
  title,
  body,
  message,
  type = 'system',
  isGlobal = false,
  data = {},
  relatedEntityId = '',
}) => {
  const recipientId = userId?._id ?? userId ?? recipient?._id ?? recipient;
  const notification = await Notification.create({
    user: recipientId,
    title,
    body: body ?? message,
    type,
    isGlobal,
    data,
    relatedEntityId:
      relatedEntityId ||
      data.bookingId ||
      data.workshopId ||
      data.verificationDocumentId ||
      '',
  });
  const payload = {
    id: notification._id.toString(),
    recipient: notification.user?.toString?.() ?? null,
    title: notification.title,
    body: notification.body,
    message: notification.body,
    type: notification.type,
    relatedEntityId: notification.relatedEntityId,
    isRead: notification.isRead,
    data: notification.data ?? {},
    time: notification.createdAt,
    createdAt: notification.createdAt,
  };
  if (recipientId) {
    emitNotification(recipientId, payload);
    sendPushNotificationToUser(recipientId, payload).catch((error) => {
      console.warn('[push] notification fallback used', error.message);
    });
  }
  return notification;
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
      recipient: item.user?.toString?.() ?? null,
      title: item.title,
      body: item.body,
      message: item.body,
      type: item.type,
      relatedEntityId: item.relatedEntityId ?? '',
      isRead: item.isRead ?? false,
      data: item.data ?? {},
      time: item.createdAt,
      createdAt: item.createdAt,
    })),
  });
});

export const getNotificationSummary = asyncHandler(async (req, res) => {
  const unread = await Notification.countDocuments({
    user: req.user._id,
    isRead: false,
  });
  res.status(200).json({ success: true, data: { unread, unreadCount: unread } });
});

export const markNotificationRead = asyncHandler(async (req, res) => {
  const notification = await Notification.findById(req.params.id);
  if (!notification) {
    return res.status(404).json({ success: false, message: 'Notification not found' });
  }
  if (
    notification.user &&
    notification.user.toString() !== req.user._id.toString()
  ) {
    return res.status(403).json({ success: false, message: 'Access denied' });
  }
  notification.isRead = true;
  await notification.save();
  res.status(200).json({ success: true, message: 'Notification marked as read' });
});

export const markAllNotificationsRead = asyncHandler(async (req, res) => {
  await Notification.updateMany(
    { user: req.user._id, isRead: false },
    { $set: { isRead: true } },
  );
  res.status(200).json({ success: true, message: 'All notifications marked as read' });
});

export const saveDeviceToken = asyncHandler(async (req, res) => {
  const { token, platform = 'unknown' } = req.body;
  if (!token || !token.trim()) {
    return res.status(400).json({ success: false, message: 'Device token is required' });
  }

  const safePlatform = ['android', 'ios', 'web', 'unknown'].includes(platform)
    ? platform
    : 'unknown';
  await User.updateOne(
    { _id: req.user._id },
    {
      $pull: { notificationTokens: { token: token.trim() } },
    },
  );
  await User.updateOne(
    { _id: req.user._id },
    {
      $push: {
        notificationTokens: {
          token: token.trim(),
          platform: safePlatform,
          updatedAt: new Date(),
        },
      },
    },
  );

  res.status(200).json({ success: true, message: 'Device token saved' });
});
