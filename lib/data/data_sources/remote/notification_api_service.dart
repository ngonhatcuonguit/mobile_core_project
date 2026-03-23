import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_core_project/data/models/notification/notification_model.dart';

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

  // ── GET /api/employee/getmessage ──────────────────────────────────────────

  /// Lấy danh sách thông báo của nhân viên.
  ///
  /// [mode] — 'ALL' | 'READ' | 'UNREAD'
  /// [page] — Trang số (bắt đầu từ 1)
  /// [pageSize] — Số item trong 1 trang
  Future<NotificationListResponse> getMessages({
    String mode = 'ALL',
    int page = 1,
    int pageSize = 10,
  }) async {
    const path = '/api/employee/getmessage';
    debugPrint('$_kTag ▶ GET ${_dio.options.baseUrl}$path?mode=$mode&page=$page&pagesize=$pageSize');

    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: {
          'mode': mode,
          'page': page,
          'pagesize': pageSize,
        },
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      debugPrint('$_kTag ◀ HTTP ${response.statusCode} $path');

      if (response.statusCode == 200) {
        final json = response.data as Map<String, dynamic>;
        return NotificationListResponse.fromJson(json);
      } else {
        debugPrint('$_kTag ✗ getMessages failed – HTTP ${response.statusCode}');
        return const NotificationListResponse(total: 0, items: []);
      }
    } on DioException catch (e) {
      debugPrint('$_kTag ❌ getMessages DioException: ${e.message}');
      return const NotificationListResponse(total: 0, items: []);
    } catch (e) {
      debugPrint('$_kTag ❌ getMessages unexpected error: $e');
      return const NotificationListResponse(total: 0, items: []);
    }
  }

  // ── GET /api/employee/hasread ──────────────────────────────────────────────

  /// Đánh dấu thông báo đã đọc.
  ///
  /// [id] — Id của thông báo
  Future<bool> markAsRead({required int id}) async {
    const path = '/api/employee/hasread';
    debugPrint('$_kTag ▶ GET ${_dio.options.baseUrl}$path?id=$id');

    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: {'id': id},
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      debugPrint('$_kTag ◀ HTTP ${response.statusCode} $path');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('$_kTag ✅ markAsRead success – id=$id');
        return true;
      } else {
        debugPrint('$_kTag ✗ markAsRead failed – HTTP ${response.statusCode}');
        return false;
      }
    } on DioException catch (e) {
      debugPrint('$_kTag ❌ markAsRead DioException: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('$_kTag ❌ markAsRead unexpected error: $e');
      return false;
    }
  }

  // ── GET /api/employee/UnreadCount ────────────────────────────────────────

  /// Lấy số lượng thông báo chưa đọc.
  /// Response: {"status":"success","data": 100}
  Future<int> getUnreadCount() async {
    const path = '/api/employee/UnreadCount';
    debugPrint('$_kTag ▶ GET ${_dio.options.baseUrl}$path');

    try {
      final response = await _dio.get<dynamic>(
        path,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      debugPrint('$_kTag ◀ HTTP ${response.statusCode} $path');

      if (response.statusCode == 200) {
        final json = response.data as Map<String, dynamic>;
        return (json['data'] as num?)?.toInt() ?? 0;
      } else {
        debugPrint('$_kTag ✗ getUnreadCount failed – HTTP ${response.statusCode}');
        return 0;
      }
    } on DioException catch (e) {
      debugPrint('$_kTag ❌ getUnreadCount DioException: ${e.message}');
      return 0;
    } catch (e) {
      debugPrint('$_kTag ❌ getUnreadCount unexpected error: $e');
      return 0;
    }
  }

  // ── POST /api/account/RegisterNotification ─────────────────────────────────

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

