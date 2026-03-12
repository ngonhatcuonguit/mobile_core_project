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

/// Response from login API
/// Success: { "status": "success", "data": { "token": "...", "username": "...", "displayname": "...", "email": "..." } }
/// Error:   { "status": "error", "message": "Tài khoản hoặc mật khẩu không chính xác" }
class LoginResponse {
  final bool isSuccess;
  final String? token;
  final String? username;
  final String? displayName;
  final String? email;
  final String? message;

  const LoginResponse({
    required this.isSuccess,
    this.token,
    this.username,
    this.displayName,
    this.email,
    this.message,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final status = json['status'] as String? ?? '';
    if (status == 'success') {
      final data = json['data'] as Map<String, dynamic>? ?? {};
      return LoginResponse(
        isSuccess: true,
        token: data['token'] as String?,
        username: data['username'] as String?,
        displayName: data['displayname'] as String?,
        email: data['email'] as String?,
      );
    } else {
      return LoginResponse(
        isSuccess: false,
        message: json['message'] as String? ?? 'Đã có lỗi xảy ra',
      );
    }
  }
}

