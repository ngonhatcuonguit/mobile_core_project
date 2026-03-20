import 'package:flutter/material.dart';
import 'package:flutter_core_project/presentation/auth/pages/sign_in.dart';
import 'package:flutter_core_project/presentation/pages/main/main_screen.dart';
import 'package:flutter_core_project/services/auth_service.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    FlutterNativeSplash.remove();
    _redirect();
  }

  @override
  Widget build(BuildContext context) {
    // Màn hình trắng tạm thời trong khi chờ redirect
    return const Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.shrink(),
    );
  }

  Future<void> _redirect() async {
    final isLoggedIn = await AuthService.isLoggedIn();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            isLoggedIn ? const MainScreen() : const SigninPage(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }
}
