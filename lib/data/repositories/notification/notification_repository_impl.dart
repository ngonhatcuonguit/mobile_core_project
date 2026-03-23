import 'package:flutter_core_project/data/data_sources/remote/notification_api_service.dart';
import 'package:flutter_core_project/data/models/notification/notification_model.dart';
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

  @override
  Future<NotificationListResponse> getMessages({
    String mode = 'ALL',
    int page = 1,
    int pageSize = 10,
  }) {
    return _notificationApiService.getMessages(
      mode: mode,
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<bool> markAsRead({required int id}) {
    return _notificationApiService.markAsRead(id: id);
  }

  @override
  Future<int> getUnreadCount() {
    return _notificationApiService.getUnreadCount();
  }
}

