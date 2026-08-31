import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_core_project/domain/entities/notification/device_token_entity.dart';
import 'package:flutter_core_project/domain/usecases/register_device_token.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) await Firebase.initializeApp();
  } catch (error) {
    debugPrint('[FCM] Background initialization skipped: $error');
  }
}

class FirebaseMessagingService {
  FirebaseMessagingService(this._registerDeviceToken);

  static const AndroidNotificationChannel androidChannel =
      AndroidNotificationChannel(
    'high_importance_channel',
    'Thong bao quan trong',
    description: 'Thong bao quan trong cua Construction Plan.',
    importance: Importance.high,
  );

  final RegisterDeviceToken _registerDeviceToken;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final StreamController<RemoteMessage> _openedMessages =
      StreamController<RemoteMessage>.broadcast();

  bool _initialized = false;
  bool _available = false;

  bool get isAvailable => _available;

  Stream<RemoteMessage> get openedMessages => _openedMessages.stream;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      _available = true;
    } catch (error) {
      debugPrint(
        '[FCM] Firebase configuration not found. Push notifications are disabled: '
        '$error',
      );
      return;
    }

    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
    await _initializeLocalNotifications();

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpenedMessage);
    messaging.onTokenRefresh.listen(_registerToken);

    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleOpenedMessage(initialMessage);
    }

    unawaited(_registerCurrentToken(messaging));
  }

  Future<String?> getToken() async {
    if (!_available) return null;
    return FirebaseMessaging.instance.getToken();
  }

  Future<void> subscribeToTopic(String topic) async {
    if (_available) {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    if (_available) {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    }
  }

  Future<void> _initializeLocalNotifications() async {
    if (kIsWeb) return;

    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('[FCM] Local notification opened: ${response.payload}');
      },
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null ||
        kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          androidChannel.id,
          androidChannel.name,
          channelDescription: androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _handleOpenedMessage(RemoteMessage message) {
    _openedMessages.add(message);
  }

  Future<void> _registerCurrentToken(FirebaseMessaging messaging) async {
    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        String? apnsToken;
        for (var attempt = 0; attempt < 5 && apnsToken == null; attempt++) {
          apnsToken = await messaging.getAPNSToken();
          if (apnsToken == null) {
            await Future<void>.delayed(const Duration(seconds: 1));
          }
        }
        if (apnsToken == null) {
          debugPrint('[FCM] APNs token is not available yet.');
          return;
        }
      }

      final token = await messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _registerToken(token);
      }
    } catch (error) {
      debugPrint('[FCM] Could not get the current token: $error');
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      await _registerDeviceToken(
        DeviceTokenEntity(token: token, platform: _platformName),
      );
    } catch (error) {
      debugPrint('[FCM] Could not register device token: $error');
    }
  }

  String get _platformName {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.linux:
        return 'linux';
      case TargetPlatform.fuchsia:
        return 'fuchsia';
    }
  }
}
