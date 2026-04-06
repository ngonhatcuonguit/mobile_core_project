import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';
  static const String _displayNameKey = 'display_name';
  static const String _tokenKey = 'auth_token';
  static const String _employeeIdKey = 'employee_id';
  static const String _positionKey = 'position';
  static const String _departmentKey = 'department';

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
    String? position,
    String? department,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_userEmailKey, email);
    if (name != null) await prefs.setString(_userNameKey, name);
    if (displayName != null) await prefs.setString(_displayNameKey, displayName);
    if (token != null) await prefs.setString(_tokenKey, token);
    if (employeeId != null) await prefs.setString(_employeeIdKey, employeeId);
    if (position != null) await prefs.setString(_positionKey, position);
    if (department != null) await prefs.setString(_departmentKey, department);
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

  /// Get position (chức vụ)
  static Future<String?> getPosition() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_positionKey);
  }

  /// Get department (phòng ban)
  static Future<String?> getDepartment() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_departmentKey);
  }

  /// Logout — clear token và toàn bộ thông tin user
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_displayNameKey);
    await prefs.remove(_tokenKey);
    await prefs.remove(_employeeIdKey);
    await prefs.remove(_positionKey);
    await prefs.remove(_departmentKey);
  }

  /// Clear all data (for testing)
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
