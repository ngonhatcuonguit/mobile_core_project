import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_core_project/firebase_options.dart';

/// Background message handler — phải là top-level function (không được là method)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Guard: chỉ khởi tạo nếu Firebase chưa được init (tránh duplicate-app error)
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }
  debugPrint('[FCM Background] message: ${message.messageId}');
}

/// Singleton service quản lý toàn bộ Firebase:
/// - Firebase Core init
/// - FCM (Push Notification)
/// - Firebase Analytics
/// - Firebase Crashlytics
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();

  // Guard: tránh gọi initialize() nhiều lần
  bool _initialized = false;

  // ─── Public accessors ───────────────────────────────────────────────────────
  // Khai báo late để tránh truy cập Firebase trước khi initializeApp() được gọi
  late FirebaseAnalytics analytics;
  late FirebaseCrashlytics crashlytics;
  late FirebaseMessaging messaging;

  // Local notifications channel (Android)
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Kênh nhận thông báo quan trọng từ MyTHP.',
    importance: Importance.high,
    playSound: true,
  );

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // ─── Initialization ──────────────────────────────────────────────────────────

  /// Gọi hàm này trong main() sau WidgetsFlutterBinding.ensureInitialized()
  Future<void> initialize() async {
    // Guard: nếu đã init rồi thì bỏ qua, tránh lỗi duplicate-app
    if (_initialized) {
      debugPrint('[Firebase] Already initialized — skipping.');
      return;
    }

    // 1. Khởi tạo Firebase Core — chỉ gọi khi chưa có app nào
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }

    // Gán các instance SAU khi Firebase đã được khởi tạo
    analytics = FirebaseAnalytics.instance;
    crashlytics = FirebaseCrashlytics.instance;
    messaging = FirebaseMessaging.instance;

    // 2. Crashlytics
    await _initCrashlytics();

    // 3. Analytics
    await _initAnalytics();

    // 4. FCM
    await _initFCM();

    _initialized = true;
    debugPrint('[Firebase] Initialized successfully.');
  }

  // ─── Crashlytics ─────────────────────────────────────────────────────────────

  Future<void> _initCrashlytics() async {
    // Bật Crashlytics (tắt trên debug nếu muốn)
    await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

    // Bắt mọi Flutter framework error và gửi lên Crashlytics
    FlutterError.onError = crashlytics.recordFlutterFatalError;

    // Bắt lỗi async không được handle (Zone errors)
    PlatformDispatcher.instance.onError = (error, stack) {
      crashlytics.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // ─── Analytics ───────────────────────────────────────────────────────────────

  Future<void> _initAnalytics() async {
    // Tắt Analytics collection trên debug build để tránh ô nhiễm data
    await analytics.setAnalyticsCollectionEnabled(!kDebugMode);
  }

  /// Log custom event — dùng khắp app
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    await analytics.logEvent(name: name, parameters: parameters);
  }

  /// Log màn hình khi navigate
  Future<void> logScreenView(String screenName, String screenClass) async {
    await analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  /// Gắn userId sau khi user đăng nhập
  Future<void> setUserId(String? userId) async {
    await analytics.setUserId(id: userId);
    if (userId != null) {
      await crashlytics.setUserIdentifier(userId);
    }
  }

  // ─── FCM ─────────────────────────────────────────────────────────────────────

  Future<void> _initFCM() async {
    // Đăng ký background handler trước tiên
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Yêu cầu quyền notification (iOS + Android 13+)
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

    // Cấu hình local notifications để hiện notification khi app foreground
    await _setupLocalNotifications();

    // Lắng nghe message khi app đang mở (foreground)
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Xử lý khi user tap notification lúc app đang background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Xử lý notification mở app từ terminated state
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpenedApp(initialMessage);
    }

    // Bật foreground notification trên iOS
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Lấy FCM token
    final token = await getFCMToken();
    debugPrint('[FCM] Token: $token');

    // Lắng nghe token refresh
    messaging.onTokenRefresh.listen((newToken) {
      debugPrint('[FCM] Token refreshed: $newToken');
      // TODO: Gửi newToken lên backend của bạn
    });
  }

  Future<void> _setupLocalNotifications() async {
    // Android init
    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS init
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
      onDidReceiveNotificationResponse: (details) {
        // TODO: Navigate theo payload khi user tap local notification
        debugPrint('[LocalNotif] tapped: ${details.payload}');
      },
    );

    // Tạo Android notification channel độ ưu tiên cao
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('[FCM Foreground] ${message.notification?.title}');
    final notification = message.notification;
    final android = message.notification?.android;

    if (notification != null && !kIsWeb) {
      _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: message.data.toString(),
      );
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('[FCM Opened] ${message.data}');
    // TODO: Điều hướng tới màn hình phù hợp dựa vào message.data
    // Ví dụ: NavigationService.navigateTo(message.data['route']);
  }

  // ─── Public helpers ───────────────────────────────────────────────────────────

  /// Lấy FCM token hiện tại của thiết bị
  Future<String?> getFCMToken() async {
    if (Platform.isIOS) {
      // iOS cần APNS token trước
      final apns = await messaging.getAPNSToken();
      if (apns == null) return null;
    }
    return messaging.getToken();
  }

  /// Ghi nhận lỗi thủ công lên Crashlytics (dùng trong catch blocks)
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    await crashlytics.recordError(
      exception,
      stack,
      reason: reason,
      fatal: fatal,
    );
  }

  /// Subscribe topic FCM
  Future<void> subscribeToTopic(String topic) async {
    await messaging.subscribeToTopic(topic);
  }

  /// Unsubscribe topic FCM
  Future<void> unsubscribeFromTopic(String topic) async {
    await messaging.unsubscribeFromTopic(topic);
  }
}

