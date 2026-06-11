/// Request body for POST /api/account/internallogin
class LoginRequest {
  final String userName;
  final String password;

  const LoginRequest({required this.userName, required this.password});

  Map<String, dynamic> toJson() => {
        'UserName': userName,
        'Password': password,
      };
}

/// Response from login API.
///
/// Backend responses in this project are not fully consistent about key casing,
/// so parsing is intentionally case-insensitive.
class LoginResponse {
  final bool isSuccess;
  final String? token;
  final String? username;
  final String? displayName;
  final String? email;
  final String? position; // Chức vụ
  final String? department; // Phòng ban
  final String? message;

  const LoginResponse({
    required this.isSuccess,
    this.token,
    this.username,
    this.displayName,
    this.email,
    this.position,
    this.department,
    this.message,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final status = _readString(json, 'status')?.toLowerCase();
    final success = status == 'success' ||
        status == 'true' ||
        _readBool(json, 'success') == true ||
        _readBool(json, 'isSuccess') == true;

    if (success) {
      final data = _readMap(json, 'data') ?? json;
      return LoginResponse(
        isSuccess: true,
        token: _readString(data, 'token'),
        username:
            _readString(data, 'username') ?? _readString(data, 'userName'),
        displayName: _readString(data, 'displayname') ??
            _readString(data, 'displayName') ??
            _readString(data, 'name'),
        email: _readString(data, 'email'),
        position: _readString(data, 'position'),
        department: _readString(data, 'department'),
      );
    } else {
      return LoginResponse(
        isSuccess: false,
        message: _readString(json, 'message') ??
            _readString(json, 'error') ??
            'Đã có lỗi xảy ra, vui lòng thử lại',
      );
    }
  }

  static Object? _readValue(Map<String, dynamic> json, String key) {
    if (json.containsKey(key)) return json[key];

    final lowerKey = key.toLowerCase();
    for (final entry in json.entries) {
      if (entry.key.toLowerCase() == lowerKey) return entry.value;
    }
    return null;
  }

  static String? _readString(Map<String, dynamic> json, String key) {
    final value = _readValue(json, key);
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static bool? _readBool(Map<String, dynamic> json, String key) {
    final value = _readValue(json, key);
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' ||
          normalized == 'success' ||
          normalized == '1') {
        return true;
      }
      if (normalized == 'false' || normalized == 'error' || normalized == '0') {
        return false;
      }
    }
    return null;
  }

  static Map<String, dynamic>? _readMap(Map<String, dynamic> json, String key) {
    final value = _readValue(json, key);
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }
}
