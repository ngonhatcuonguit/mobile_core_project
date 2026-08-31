import 'package:flutter_core_project/data/data_sources/local/notification_local_data_source.dart';
import 'package:flutter_core_project/data/data_sources/remote/notification_remote_data_source.dart';
import 'package:flutter_core_project/domain/entities/notification/device_token_entity.dart';
import 'package:flutter_core_project/domain/repository/notification/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  const NotificationRepositoryImpl({
    required NotificationLocalDataSource localDataSource,
    required NotificationRemoteDataSource remoteDataSource,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource;

  final NotificationLocalDataSource _localDataSource;
  final NotificationRemoteDataSource _remoteDataSource;

  @override
  String? get cachedToken => _localDataSource.token;

  @override
  Future<void> registerDevice(DeviceTokenEntity device) async {
    await _localDataSource.saveToken(device.token);
    await _remoteDataSource.registerDevice(device);
  }
}
