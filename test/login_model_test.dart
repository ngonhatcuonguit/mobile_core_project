import 'package:flutter_core_project/data/models/auth/login_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoginResponse', () {
    test('parses success response with lowercase keys', () {
      final response = LoginResponse.fromJson({
        'status': 'success',
        'data': {
          'token': 'token-1',
          'username': '43950',
          'displayname': 'Nguyen Van A',
          'email': 'a@example.com',
          'position': 'Staff',
          'department': 'IT',
        },
      });

      expect(response.isSuccess, isTrue);
      expect(response.token, 'token-1');
      expect(response.username, '43950');
      expect(response.displayName, 'Nguyen Van A');
      expect(response.email, 'a@example.com');
      expect(response.position, 'Staff');
      expect(response.department, 'IT');
    });

    test('parses success response with uppercase keys', () {
      final response = LoginResponse.fromJson({
        'Status': 'Success',
        'Data': {
          'Token': 'token-2',
          'UserName': '43951',
          'DisplayName': 'Tran Van B',
        },
      });

      expect(response.isSuccess, isTrue);
      expect(response.token, 'token-2');
      expect(response.username, '43951');
      expect(response.displayName, 'Tran Van B');
    });

    test('parses server error message case-insensitively', () {
      final response = LoginResponse.fromJson({
        'Status': 'error',
        'Message': 'Tai khoan hoac mat khau khong chinh xac',
      });

      expect(response.isSuccess, isFalse);
      expect(response.message, 'Tai khoan hoac mat khau khong chinh xac');
    });
  });
}
