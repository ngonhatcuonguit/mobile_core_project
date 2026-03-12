import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  static const String _displayNameKey = 'display_name';
  static const String _tokenKey = 'auth_token';
  static const String _employeeIdKey = 'employee_id';

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  /// Save login state from real API response
  static Future<void> setLoggedIn({
    required String email,
    String? name,
    String? displayName,
    String? token,
    String? employeeId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_userEmailKey, email);
    if (name != null) await prefs.setString(_userNameKey, name);
    if (displayName != null) await prefs.setString(_displayNameKey, displayName);
    if (token != null) await prefs.setString(_tokenKey, token);
    if (employeeId != null) await prefs.setString(_employeeIdKey, employeeId);
  }

  /// Get auth token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Get user email
  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  /// Get user name (username = employee id)
  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  /// Get display name
  static Future<String?> getDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_displayNameKey);
  }

  /// Get employee id (same as username from login API)
  static Future<String?> getEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_employeeIdKey);
  }

  /// Logout — clear token và toàn bộ thông tin user để bảo vệ dữ liệu
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_displayNameKey);
    await prefs.remove(_tokenKey);
    await prefs.remove(_employeeIdKey);
  }

  /// Clear all data (for testing)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
