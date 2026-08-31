import 'package:flutter_core_project/core/storage/local_storage.dart';

abstract class NotificationLocalDataSource {
  String? get token;

  Future<void> saveToken(String token);
}

class NotificationLocalDataSourceImpl implements NotificationLocalDataSource {
  const NotificationLocalDataSourceImpl(this._storage);

  final LocalStorage _storage;

  @override
  String? get token => _storage.readString(StorageKeys.fcmToken);

  @override
  Future<void> saveToken(String token) {
    return _storage.writeString(StorageKeys.fcmToken, token);
  }
}
