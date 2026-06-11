import 'dart:convert';

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

    final statusCode = response.statusCode ?? 0;
    if (statusCode < 200 || statusCode >= 300) {
      final message =
          _extractMessage(raw) ?? response.statusMessage ?? 'HTTP $statusCode';
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
        message: message,
      );
    }

    if (raw == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Không nhận được dữ liệu từ server',
      );
    }

    final data = _asJsonMap(raw);

    return LoginResponse.fromJson(data);
  }

  Map<String, dynamic> _asJsonMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String) {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    }
    throw FormatException(
        'Login response không đúng định dạng JSON object: ${raw.runtimeType}');
  }

  String? _extractMessage(dynamic raw) {
    try {
      final data = _asJsonMap(raw);
      final value = data['message'] ?? data['Message'] ?? data['error'];
      return value?.toString();
    } catch (_) {
      return null;
    }
  }
}
