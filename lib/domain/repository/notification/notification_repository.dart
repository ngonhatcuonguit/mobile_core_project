import 'package:flutter_core_project/domain/entities/notification/device_token_entity.dart';

abstract class NotificationRepository {
  Future<void> registerDevice(DeviceTokenEntity device);

  String? get cachedToken;
}
