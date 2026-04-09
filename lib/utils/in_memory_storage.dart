import 'package:hydrated_bloc/hydrated_bloc.dart';

/// In-memory implementation of [Storage] dùng làm fallback khi
/// [HydratedStorage.build()] thất bại (file system không truy cập được).
///
/// State KHÔNG được persist giữa các lần khởi động app,
/// nhưng app vẫn chạy bình thường mà không crash.
class InMemoryStorage implements Storage {
  final Map<String, dynamic> _data = {};

  @override
  dynamic read(String key) => _data[key];

  @override
  Future<void> write(String key, dynamic value) async {
    _data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> clear() async {
    _data.clear();
  }

  @override
  Future<void> close() async {
    _data.clear();
  }
}

