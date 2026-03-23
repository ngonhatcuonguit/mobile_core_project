import 'package:flutter_core_project/data/data_sources/remote/notification_api_service.dart';
import 'package:flutter_core_project/data/models/notification/notification_model.dart';

/// Abstract repository — domain layer không biết về Dio hay HTTP
abstract class NotificationRepository {
  /// Đăng ký FCM token của thiết bị với backend.
  Future<bool> registerDevice({
    required String deviceRegistrationId,
    DeviceType? deviceType,
  });

  /// Lấy danh sách thông báo.
  Future<NotificationListResponse> getMessages({
    String mode,
    int page,
    int pageSize,
  });

  /// Đánh dấu thông báo đã đọc.
  Future<bool> markAsRead({required int id});

  /// Lấy số lượng thông báo chưa đọc.
  Future<int> getUnreadCount();
}

