import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Tag dùng để filter log trong Logcat / console
const String _kTag = '[THP_API]';

/// Enum platform của device — map sang string mà BE yêu cầu
enum DeviceType { android, ios, web }

extension DeviceTypeExt on DeviceType {
  String get value {
    switch (this) {
      case DeviceType.android:
        return 'Android';
      case DeviceType.ios:
        return 'IOS';
      case DeviceType.web:
        return 'Web';
    }
  }
}

/// Tự động detect platform hiện tại
DeviceType get currentDeviceType {
  if (kIsWeb) return DeviceType.web;
  if (Platform.isIOS) return DeviceType.ios;
  return DeviceType.android;
}

/// Data Source: gửi FCM registration token lên server
/// POST /api/account/RegisterNotification
class NotificationApiService {
  final Dio _dio;

  NotificationApiService(this._dio);

  /// Đăng ký FCM token của thiết bị với backend để BE có thể gửi push notification.
  ///
  /// [deviceRegistrationId] — FCM token lấy từ FirebaseMessaging.instance.getToken()
  /// [deviceType] — platform của device (Android / IOS / Web), mặc định tự detect
  Future<bool> registerDevice({
    required String deviceRegistrationId,
    DeviceType? deviceType,
  }) async {
    const path = '/api/account/RegisterNotification';
    final type = deviceType ?? currentDeviceType;

    final body = {
      'DeviceType': type.value,
      'DeviceRegistrationID': deviceRegistrationId,
    };

    debugPrint('$_kTag ▶ POST ${_dio.options.baseUrl}$path');
    debugPrint('$_kTag   Body: {DeviceType: ${type.value}, DeviceRegistrationID: $deviceRegistrationId}');

    try {
      final response = await _dio.post<dynamic>(
        path,
        data: body,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      debugPrint('$_kTag ◀ HTTP ${response.statusCode} $path');
      final rawBody = response.data?.toString() ?? 'null';
      final preview = rawBody.length > 2000 ? '${rawBody.substring(0, 2000)}...[truncated]' : rawBody;
      debugPrint('$_kTag   Response body: $preview');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('$_kTag ✅ RegisterNotification success – DeviceType=${type.value}');
        return true;
      } else {
        debugPrint('$_kTag ✗ RegisterNotification failed – HTTP ${response.statusCode}');
        return false;
      }
    } on DioException catch (e) {
      debugPrint('$_kTag ❌ RegisterNotification DioException: ${e.message} | type=${e.type} | status=${e.response?.statusCode}');
      return false;
    } catch (e) {
      debugPrint('$_kTag ❌ RegisterNotification unexpected error: $e');
      return false;
    }
  }
}

