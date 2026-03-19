import 'package:flutter_core_project/data/data_sources/remote/notification_api_service.dart';
import 'package:flutter_core_project/domain/repository/notification/notification_repository.dart';

/// UseCase: Đăng ký FCM device token lên backend để nhận Push Notification.
///
/// Gọi sau khi:
///  - App khởi động và lấy được FCM token lần đầu
///  - Firebase gọi onTokenRefresh (token bị làm mới)
class RegisterDeviceUseCase {
  final NotificationRepository _repository;

  RegisterDeviceUseCase(this._repository);

  /// [deviceRegistrationId] — FCM token từ FirebaseMessaging.instance.getToken()
  /// [deviceType] — tự detect nếu không truyền vào
  Future<bool> call({
    required String deviceRegistrationId,
    DeviceType? deviceType,
  }) {
    return _repository.registerDevice(
      deviceRegistrationId: deviceRegistrationId,
      deviceType: deviceType,
    );
  }
}

