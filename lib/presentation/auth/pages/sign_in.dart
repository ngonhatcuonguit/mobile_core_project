import 'package:flutter/material.dart';
import 'package:flutter_core_project/common/helpers/is_dark_mode.dart';
import 'package:flutter_core_project/data/data_sources/remote/login_api_service.dart';
import 'package:flutter_core_project/injection_container.dart';
import 'package:flutter_core_project/presentation/auth/pages/sign_up.dart';
import 'package:flutter_core_project/presentation/pages/main/main_screen.dart';
import 'package:flutter_core_project/presentation/widgets/appbar/app_bar.dart';
import 'package:flutter_core_project/services/auth_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dio/dio.dart';

import '../../../common/widgets/button/basic_app_button.dart';
import '../../../core/configs/assets/app_vectors.dart';

class SigninPage extends StatefulWidget {
  const SigninPage({super.key});

  @override
  State<SigninPage> createState() => _SigninPageState();
}

class _SigninPageState extends State<SigninPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty) {
      _showErrorDialog('Vui lòng nhập tên đăng nhập');
      return;
    }
    if (password.isEmpty) {
      _showErrorDialog('Vui lòng nhập mật khẩu');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Use injected service with correct base URL (https://mythp-api.thp.com.vn)
      final loginService = sl<LoginApiService>();
      final result = await loginService.login(
        userName: username,
        password: password,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        // Lưu token và thông tin user
        debugPrint('[LOGIN] ✅ username=${result.username} displayName=${result.displayName} token=${result.token?.isNotEmpty}');
        await AuthService.setLoggedIn(
          email: result.email ?? '',
          name: result.username,
          displayName: result.displayName,
          token: result.token,
          employeeId: result.username, // username chính là employee id
        );

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      } else {
        _showErrorDialog(result.message ?? 'Đăng nhập thất bại');
      }
    } on DioException catch (e) {
      if (!mounted) return;
      _showErrorDialog(e.message ?? 'Lỗi kết nối, vui lòng thử lại');
    } catch (e) {
      if (!mounted) return;
      _showErrorDialog('Đã có lỗi xảy ra, vui lòng thử lại');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFF44545)),
            const SizedBox(width: 8),
            const Text('Đăng nhập thất bại'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng', style: TextStyle(color: Color(0xFFF44545))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BasicAppBar(
        title: SvgPicture.asset(
          AppVectors.logo,
          height: 30,
          width: 30,
        ),
      ),
      bottomNavigationBar: _signupText(context),
      body: Padding(
          padding: const EdgeInsets.all(50),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _registerText(context),
              const SizedBox(height: 20),
              _usernameField(context),
              const SizedBox(height: 20),
              _passwordField(context),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : BasicAppButton(
                      title: 'Đăng nhập',
                      onPressed: _handleLogin,
                    ),
            ],
          ),
        ),
    );
  }

  Widget _registerText(BuildContext context) {
    return Text(
      'Đăng Nhập',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: context.isDarkMode ? Colors.white : Colors.black,
        fontSize: 25,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _usernameField(BuildContext context) {
    return TextField(
      controller: _usernameController,
      keyboardType: TextInputType.text,
      decoration: const InputDecoration(
        hintText: 'Nhập mã nhân viên',
      ).applyDefaults(
        Theme.of(context).inputDecorationTheme,
      ),
    );
  }

  Widget _passwordField(BuildContext context) {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        hintText: 'Nhập mật khẩu',
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
      ).applyDefaults(
        Theme.of(context).inputDecorationTheme,
      ),
    );
  }

  Widget _signupText(BuildContext context) {
    return TextButton(
      onPressed: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Chưa có tài khoản?',
              style: TextStyle(
                color: context.isDarkMode ? Colors.white : Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const SignUpPage()),
                );
              },
              child: const Text(
                'Đăng ký ngay',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
