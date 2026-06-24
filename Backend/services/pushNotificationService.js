import User from '../models/User.js';
import admin from 'firebase-admin';

let firebaseReady = false;

const getServiceAccount = () => {
  const raw =
    process.env.FCM_SERVICE_ACCOUNT_JSON || process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (!raw) return null;
  try {
    const parsed = JSON.parse(raw);
    if (parsed.private_key) {
      parsed.private_key = parsed.private_key.replace(/\\n/g, '\n');
    }
    return parsed;
  } catch (error) {
    console.warn('[push] invalid Firebase service account JSON', error.message);
    return null;
  }
};

const getMessaging = () => {
  if (admin.apps.length) return admin.messaging();
  const serviceAccount = getServiceAccount();
  if (!serviceAccount) return null;

  try {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    firebaseReady = true;
    return admin.messaging();
  } catch (error) {
    console.warn('[push] Firebase Admin initialization failed', error.message);
    firebaseReady = false;
    return null;
  }
};

export const sendPushNotificationToUser = async (userId, payload) => {
  if (!userId) return { sent: false, reason: 'missing_user' };

  const user = await User.findById(userId).select('+notificationTokens');
  const tokens = user?.notificationTokens?.map((item) => item.token).filter(Boolean) ?? [];
  if (!tokens.length) return { sent: false, reason: 'no_device_tokens' };

  const messaging = getMessaging();
  if (!messaging) {
    return { sent: false, reason: 'fcm_not_configured' };
  }

  const message = {
    tokens: [...new Set(tokens)],
    notification: {
      title: payload?.title || 'Salahny',
      body: payload?.body || 'You have a new notification.',
    },
    data: Object.fromEntries(
      Object.entries({
        id: payload?.id,
        type: payload?.type,
        ...(payload?.data ?? {}),
      })
        .filter(([, value]) => value !== undefined && value !== null)
        .map(([key, value]) => [key, String(value)]),
    ),
    android: {
      priority: 'high',
      notification: {
        channelId: 'salahny_notifications',
        sound: 'default',
      },
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
        },
      },
    },
  };

  const response = await messaging.sendEachForMulticast(message);
  const invalidTokens = [];
  response.responses.forEach((item, index) => {
    const code = item.error?.code;
    if (
      code === 'messaging/registration-token-not-registered' ||
      code === 'messaging/invalid-registration-token'
    ) {
      invalidTokens.push(message.tokens[index]);
    }
  });

  if (invalidTokens.length) {
    await User.updateOne(
      { _id: userId },
      { $pull: { notificationTokens: { token: { $in: invalidTokens } } } },
    );
  }

  return {
    sent: response.successCount > 0,
    successCount: response.successCount,
    failureCount: response.failureCount,
    firebaseReady,
  };
};
