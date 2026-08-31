import 'package:flutter_core_project/core/configs/app_config.dart';
import 'package:flutter_core_project/core/network/api_client.dart';
import 'package:flutter_core_project/domain/entities/notification/device_token_entity.dart';

abstract class NotificationRemoteDataSource {
  Future<void> registerDevice(DeviceTokenEntity device);
}

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  const NotificationRemoteDataSourceImpl(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<void> registerDevice(DeviceTokenEntity device) async {
    if (!AppConfig.hasFcmTokenEndpoint) return;

    await _apiClient.post<Object?>(
      AppConfig.fcmTokenEndpoint,
      data: {
        'deviceRegistrationId': device.token,
        'platform': device.platform,
      },
    );
  }
}
