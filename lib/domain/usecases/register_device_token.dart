import 'package:flutter_core_project/domain/entities/notification/device_token_entity.dart';
import 'package:flutter_core_project/domain/repository/notification/notification_repository.dart';
import 'package:flutter_core_project/domain/usecases/usecase.dart';

class RegisterDeviceToken implements UseCase<void, DeviceTokenEntity> {
  const RegisterDeviceToken(this._repository);

  final NotificationRepository _repository;

  @override
  Future<void> call(DeviceTokenEntity params) {
    return _repository.registerDevice(params);
  }
}
