import 'package:shared_preferences/shared_preferences.dart';

abstract class LocalStorage {
  String? readString(String key);

  bool? readBool(String key);

  Future<void> writeString(String key, String value);

  Future<void> writeBool(String key, bool value);

  Future<void> remove(String key);

  Future<void> clear();
}

class SharedPreferencesLocalStorage implements LocalStorage {
  const SharedPreferencesLocalStorage(this._preferences);

  final SharedPreferences _preferences;

  @override
  String? readString(String key) => _preferences.getString(key);

  @override
  bool? readBool(String key) => _preferences.getBool(key);

  @override
  Future<void> writeString(String key, String value) async {
    await _preferences.setString(key, value);
  }

  @override
  Future<void> writeBool(String key, bool value) async {
    await _preferences.setBool(key, value);
  }

  @override
  Future<void> remove(String key) async {
    await _preferences.remove(key);
  }

  @override
  Future<void> clear() async {
    await _preferences.clear();
  }
}

class StorageKeys {
  StorageKeys._();

  static const authToken = 'auth_token';
  static const fcmToken = 'fcm_token';
}
