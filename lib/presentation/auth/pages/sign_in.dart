import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_core_project/core/configs/assets/app_vectors.dart';
import 'package:flutter_core_project/core/configs/theme/app_colors.dart';
import 'package:flutter_core_project/data/data_sources/remote/login_api_service.dart';
import 'package:flutter_core_project/injection_container.dart';
import 'package:flutter_core_project/presentation/pages/main/main_screen.dart';
import 'package:flutter_core_project/services/auth_service.dart';
import 'package:flutter_core_project/services/firebase_service.dart';
import 'package:flutter_core_project/services/localization_service.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SigninPage extends StatefulWidget {
  const SigninPage({super.key});

  @override
  State<SigninPage> createState() => _SigninPageState();
}

class _SigninPageState extends State<SigninPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _usernameFocused = false;
  bool _passwordFocused = false;

  @override
  void initState() {
    super.initState();
    _usernameFocus.addListener(() =>
        setState(() => _usernameFocused = _usernameFocus.hasFocus));
    _passwordFocus.addListener(() =>
        setState(() => _passwordFocused = _passwordFocus.hasFocus));
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final l = AppLocalizations.of(context);
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty) {
      _showError(l?.translate('login_error_empty_username') ?? 'Vui lòng nhập mã nhân viên');
      return;
    }
    if (password.isEmpty) {
      _showError(l?.translate('login_error_empty_password') ?? 'Vui lòng nhập mật khẩu');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await sl<LoginApiService>().login(
        userName: username,
        password: password,
      );
      if (!mounted) return;
      if (result.isSuccess) {
        await AuthService.setLoggedIn(
          email: result.email ?? '',
          name: result.username,
          displayName: result.displayName,
          token: result.token,
          employeeId: result.username,
          position: result.position,
          department: result.department,
        );
        // Gửi FCM token cho account vừa đăng nhập (kể cả khi đổi sang account khác)
        // fire-and-forget — không cần chờ, không block navigation
        FirebaseService.instance.registerCurrentDevice();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
      } else {
        _showError(result.message ?? 'Đăng nhập thất bại');
      }
    } on DioException catch (e) {
      if (mounted) _showError(e.message ?? 'Lỗi kết nối, vui lòng thử lại');
    } catch (_) {
      if (mounted) _showError('Đã có lỗi xảy ra, vui lòng thử lại');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    final l = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFF44545)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                l?.translate('login_failed') ?? 'Đăng nhập thất bại',
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              l?.translate('login_close') ?? 'Đóng',
              style: const TextStyle(color: Color(0xFFF44545)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Stack(
        children: [
          // ── top decorative arc ────────────────────────────────────────
          Positioned(
            top: -size.width * 0.35,
            right: -size.width * 0.2,
            child: Container(
              width: size.width * 0.9,
              height: size.width * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ),
          Positioned(
            top: -size.width * 0.5,
            right: -size.width * 0.35,
            child: Container(
              width: size.width * 1.0,
              height: size.width * 1.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.45),
              ),
            ),
          ),
          // ── bottom decorative arc ─────────────────────────────────────
          Positioned(
            bottom: -size.width * 0.35,
            left: -size.width * 0.2,
            child: Container(
              width: size.width * 0.9,
              height: size.width * 0.9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.55),
              ),
            ),
          ),

          // ── main content ──────────────────────────────────────────────
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 48),

                  // Logo
                  Center(
                    child: SvgPicture.asset(
                      AppVectors.thp_logo,
                      height: 80,
                      width: 80,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Center(
                    child: Text(
                      l?.translate('login_title') ?? 'Đăng nhập',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Subtitle
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                          height: 1.5,
                        ),
                        children: [
                          TextSpan(text: l?.translate('login_welcome') ?? 'Chào mừng trở lại,'),
                          const TextSpan(text: '\n'),
                          TextSpan(text: l?.translate('login_welcome_sub') ?? 'chúng tôi nhớ bạn!'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Username field ───────────────────────────────────
                  _buildTextField(
                    controller: _usernameController,
                    focusNode: _usernameFocus,
                    isFocused: _usernameFocused,
                    hint: l?.translate('login_msnv') ?? 'Mã nhân viên',
                    obscure: false,
                  ),
                  const SizedBox(height: 16),

                  // ── Password field ───────────────────────────────────
                  _buildTextField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    isFocused: _passwordFocused,
                    hint: l?.translate('login_password') ?? 'Mật khẩu',
                    obscure: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: const Color(0xFF9E9E9E),
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── Forgot password ─────────────────────────────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        l?.translate('login_forgot_password') ?? 'Quên mật khẩu?',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ── Sign in button ──────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              l?.translate('login_sign_in') ?? 'Đăng nhập',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isFocused,
    required String hint,
    required bool obscure,
    Widget? suffixIcon,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isFocused ? Colors.white : const Color(0xFFEEF0F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFocused ? AppColors.primary : Colors.transparent,
          width: 1.8,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                )
              ]
            : [],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscure,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1A1A1A),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFF9E9E9E),
            fontWeight: FontWeight.w400,
            fontSize: 15,
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}
