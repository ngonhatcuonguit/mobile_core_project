import 'package:flutter_core_project/data/data_sources/remote/notification_api_service.dart';

/// Abstract repository — domain layer không biết về Dio hay HTTP
abstract class NotificationRepository {
  /// Đăng ký FCM token của thiết bị với backend.
  /// Trả về [true] nếu thành công, [false] nếu thất bại (lỗi không throw ra ngoài).
  Future<bool> registerDevice({
    required String deviceRegistrationId,
    DeviceType? deviceType,
  });
}

