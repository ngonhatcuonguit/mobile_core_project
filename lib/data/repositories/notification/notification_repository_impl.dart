import 'package:flutter_core_project/data/data_sources/remote/notification_api_service.dart';
import 'package:flutter_core_project/domain/repository/notification/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationApiService _notificationApiService;

  NotificationRepositoryImpl(this._notificationApiService);

  @override
  Future<bool> registerDevice({
    required String deviceRegistrationId,
    DeviceType? deviceType,
  }) {
    return _notificationApiService.registerDevice(
      deviceRegistrationId: deviceRegistrationId,
      deviceType: deviceType,
    );
  }
}

