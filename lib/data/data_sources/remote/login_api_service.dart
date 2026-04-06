import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_core_project/data/models/auth/login_model.dart';

/// Tìm log trong Logcat bằng tag: [THP_API]
const String _kLoginApiTag = '[THP_API]';

class LoginApiService {
  final Dio _dio;

  LoginApiService(this._dio);

  /// POST /api/account/internallogin
  /// Body: { "UserName": "43950", "Password": "..." }
  Future<LoginResponse> login({
    required String userName,
    required String password,
  }) async {
    const path = '/api/account/internallogin';
    final body = LoginRequest(userName: userName, password: password).toJson();

    debugPrint('$_kLoginApiTag ▶ POST ${_dio.options.baseUrl}$path');
    debugPrint('$_kLoginApiTag   Body: {UserName: $userName, Password: ***}');

    final response = await _dio.post<dynamic>(
      path,
      data: body,
      options: Options(
        validateStatus: (status) => status != null && status < 500,
        // Bỏ qua global error dialog — màn hình login tự xử lý lỗi credentials
        extra: {'skipErrorDialog': true},
      ),
    );

    debugPrint('$_kLoginApiTag ◀ HTTP ${response.statusCode} $path');

    final raw = response.data;
    debugPrint('$_kLoginApiTag   Response: $raw');

    if (raw == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Không nhận được dữ liệu từ server',
      );
    }

    final Map<String, dynamic> data =
        raw is Map<String, dynamic> ? raw : Map<String, dynamic>.from(raw as Map);

    return LoginResponse.fromJson(data);
  }
}
