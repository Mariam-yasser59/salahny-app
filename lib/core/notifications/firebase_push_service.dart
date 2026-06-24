import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../network/api_client.dart';
import '../storage/token_storage.dart';

const _firebaseApiKey = String.fromEnvironment('SALAHNY_FIREBASE_API_KEY');
const _firebaseAppId = String.fromEnvironment('SALAHNY_FIREBASE_APP_ID');
const _firebaseMessagingSenderId = String.fromEnvironment(
  'SALAHNY_FIREBASE_MESSAGING_SENDER_ID',
);
const _firebaseProjectId = String.fromEnvironment(
  'SALAHNY_FIREBASE_PROJECT_ID',
);
const _firebaseStorageBucket = String.fromEnvironment(
  'SALAHNY_FIREBASE_STORAGE_BUCKET',
);
const _firebaseIosBundleId = String.fromEnvironment(
  'SALAHNY_FIREBASE_IOS_BUNDLE_ID',
);

bool get _firebaseConfigured =>
    _firebaseApiKey.isNotEmpty &&
    _firebaseAppId.isNotEmpty &&
    _firebaseMessagingSenderId.isNotEmpty &&
    _firebaseProjectId.isNotEmpty;

FirebaseOptions get _firebaseOptions => FirebaseOptions(
  apiKey: _firebaseApiKey,
  appId: _firebaseAppId,
  messagingSenderId: _firebaseMessagingSenderId,
  projectId: _firebaseProjectId,
  storageBucket: _firebaseStorageBucket.isEmpty ? null : _firebaseStorageBucket,
  iosBundleId: _firebaseIosBundleId.isEmpty ? null : _firebaseIosBundleId,
);

@pragma('vm:entry-point')
Future<void> salahnyFirebaseBackgroundHandler(RemoteMessage message) async {
  if (_firebaseConfigured && Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: _firebaseOptions);
  }
}

class FirebasePushService {
  FirebasePushService._();

  static final FirebasePushService instance = FirebasePushService._();

  static const _channel = AndroidNotificationChannel(
    'salahny_notifications',
    'Salahny Notifications',
    description: 'Account approvals, bookings, chats, and emergency updates.',
    importance: Importance.high,
  );

  final _localNotifications = FlutterLocalNotificationsPlugin();
  final _api = ApiClient();
  StreamSubscription<String>? _tokenRefreshSub;
  bool _initialized = false;

  bool get isConfigured => _firebaseConfigured;

  Future<void> initialize() async {
    if (_initialized || !_firebaseConfigured) return;

    try {
      await Firebase.initializeApp(options: _firebaseOptions);
      FirebaseMessaging.onBackgroundMessage(salahnyFirebaseBackgroundHandler);

      await _localNotifications.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(),
        ),
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(_channel);

      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen(_showForegroundNotification);
      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen(
        (_) => registerDeviceToken(),
      );

      _initialized = true;
      await registerDeviceToken();
    } catch (_) {
      // Firebase is optional for the app boot path. If credentials are missing
      // or invalid, in-app notifications still work through REST/socket.
    }
  }

  Future<void> registerDeviceToken() async {
    if (!_firebaseConfigured) return;
    final authToken = await TokenStorage.getToken();
    if (authToken == null || authToken.isEmpty) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await _api.post('/notifications/device-token', {
        'token': token,
        'platform': kIsWeb
            ? 'web'
            : Platform.isIOS
            ? 'ios'
            : Platform.isAndroid
            ? 'android'
            : 'unknown',
      });
    } catch (_) {
      // Push registration should never block login or app startup.
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] ?? 'Salahny';
    final body =
        notification?.body ?? message.data['body'] ?? 'New notification';

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> dispose() async {
    await _tokenRefreshSub?.cancel();
  }
}
