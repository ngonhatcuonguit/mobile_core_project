import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_core_project/core/configs/theme/app_colors.dart';
import 'package:flutter_core_project/data/data_sources/remote/login_api_service.dart';
import 'package:flutter_core_project/injection_container.dart';
import 'package:flutter_core_project/presentation/pages/main/main_screen.dart';
import 'package:flutter_core_project/services/auth_service.dart';
import 'package:flutter_core_project/services/firebase_service.dart';
import 'package:flutter_core_project/services/localization_service.dart';

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
    _usernameFocus.addListener(
        () => setState(() => _usernameFocused = _usernameFocus.hasFocus));
    _passwordFocus.addListener(
        () => setState(() => _passwordFocused = _passwordFocus.hasFocus));
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
      _showError(l?.translate('login_error_empty_username') ??
          'Vui lòng nhập tên tài khoản');
      return;
    }
    if (password.isEmpty) {
      _showError(l?.translate('login_error_empty_password') ??
          'Vui lòng nhập mật khẩu');
      return;
    }

    setState(() => _isLoading = true);
    try {
      // ── Kiểm tra DI trước khi gọi service ─────────────────────────────────
      // Nếu initializeDependencies() chưa hoàn tất (ví dụ Firebase fail khi
      // khởi động), LoginApiService sẽ chưa được đăng ký và GetIt sẽ throw.
      // Thử khởi tạo lại nếu chưa có.
      if (!sl.isRegistered<LoginApiService>()) {
        debugPrint(
            '[Login] ⚠️ LoginApiService chưa được đăng ký, thử khởi tạo lại...');
        await initializeDependencies();
      }

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
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainScreen()),
        );
        // Gửi FCM token cho account vừa đăng nhập (kể cả khi đổi sang account khác).
        // Đây là tác vụ phụ: không được làm fail luồng login.
        unawaited(FirebaseService.instance.registerCurrentDevice());
      } else {
        _showError(result.message ?? 'Đăng nhập thất bại');
      }
    } on DioException catch (e) {
      debugPrint(
          '[Login] DioException: type=${e.type} msg=${e.message} error=${e.error?.runtimeType}: ${e.error}');
      String msg = e.message ?? 'Lỗi kết nối, vui lòng thử lại';
      if (e.type == DioExceptionType.connectionError) {
        msg =
            'Không thể kết nối tới máy chủ. Vui lòng kiểm tra mạng và thử lại.';
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        msg = 'Kết nối hết thời gian, vui lòng thử lại.';
      }
      if (kDebugMode) {
        msg = '[DioException ${e.type}] ${e.message}\nInner: ${e.error}';
      }
      if (mounted) {
        _showError(msg);
      }
    } on HandshakeException catch (e) {
      // iOS ATS hoặc SSL handshake thất bại
      debugPrint('[Login] HandshakeException: $e');
      if (mounted) {
        _showError(kDebugMode
            ? '[HandshakeException] $e'
            : 'Không thể kết nối tới máy chủ (SSL). Vui lòng thử lại.');
      }
    } on TlsException catch (e) {
      // TlsException là parent của HandshakeException & CertificateException (Dart mới)
      debugPrint('[Login] TlsException: $e');
      if (mounted) {
        _showError(kDebugMode
            ? '[TlsException] $e'
            : 'Lỗi bảo mật kết nối (TLS). Vui lòng thử lại.');
      }
    } on SocketException catch (e) {
      debugPrint('[Login] SocketException: $e');
      if (mounted) {
        _showError(kDebugMode
            ? '[SocketException] $e'
            : 'Không có kết nối mạng, vui lòng thử lại.');
      }
    } on IOException catch (e) {
      // Bắt tất cả IO exception còn lại (HttpException, OSError, v.v.)
      debugPrint('[Login] IOException (${e.runtimeType}): $e');
      if (mounted) {
        _showError(kDebugMode
            ? '[${e.runtimeType}] $e'
            : 'Lỗi kết nối, vui lòng thử lại.');
      }
    } catch (e, stack) {
      debugPrint('[Login] Unknown error (${e.runtimeType}): $e\n$stack');
      // Trong debug mode: hiện loại lỗi thực sự để dễ chẩn đoán
      if (mounted) {
        _showError(kDebugMode
            ? '[${e.runtimeType}] $e'
            : 'Đã có lỗi xảy ra, vui lòng thử lại');
      }
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
    final welcomeText = l?.translate('login_welcome') ??
        'Ung dung ho tro nguoi lao dong quan ly lich lam viec, loi nhac va thong tin cong viec ca nhan.';
    final welcomeSubText = l?.translate('login_welcome_sub') ?? '';
    // final supportNote = l?.translate('login_support_note') ??
    //     'Ket noi doanh nghiep la tuy chon. Lien he ho tro neu ban can cap quyen truy cap.';

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
                    child: Image.asset(
                      'assets/images/app_launcher_icon.png',
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
                    child: Text(
                      welcomeSubText.trim().isEmpty
                          ? welcomeText
                          : '$welcomeText\n$welcomeSubText',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── Username field ───────────────────────────────────
                  _buildTextField(
                    controller: _usernameController,
                    focusNode: _usernameFocus,
                    isFocused: _usernameFocused,
                    hint: l?.translate('login_msnv') ?? 'Tài khoản',
                    obscure: false,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                    onSubmitted: (_) => _passwordFocus.requestFocus(),
                  ),
                  const SizedBox(height: 16),

                  // ── Password field ───────────────────────────────────
                  _buildTextField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    isFocused: _passwordFocused,
                    hint: l?.translate('login_password') ?? 'Mật khẩu',
                    obscure: _obscurePassword,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => _handleLogin(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: const Color(0xFF9E9E9E),
                        size: 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── Forgot password ─────────────────────────────────
                  // TODO: Ẩn tạm thời — chức năng chưa hoàn thiện
                  const SizedBox.shrink(),
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
                        disabledBackgroundColor:
                            AppColors.primary.withOpacity(0.6),
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
                  const SizedBox(height: 12),
                  // Center(
                  //   child: Text(
                  //     supportNote,
                  //     textAlign: TextAlign.center,
                  //     style: const TextStyle(
                  //       fontSize: 13,
                  //       fontWeight: FontWeight.w500,
                  //       color: Color(0xFF6E7280),
                  //       height: 1.45,
                  //     ),
                  //   ),
                  // ),
                  // const SizedBox(height: 40),
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
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Iterable<String>? autofillHints,
    ValueChanged<String>? onSubmitted,
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
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        autofillHints: autofillHints,
        autocorrect: false,
        enableSuggestions: false,
        smartDashesType: SmartDashesType.disabled,
        smartQuotesType: SmartQuotesType.disabled,
        textCapitalization: TextCapitalization.none,
        onSubmitted: onSubmitted,
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
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}
