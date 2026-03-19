import 'package:flutter/material.dart';
import 'package:flutter_core_project/core/configs/assets/app_vectors.dart';
import 'package:flutter_core_project/presentation/intro/pages/get_started.dart';
import 'package:flutter_core_project/presentation/pages/main/main_screen.dart';
import 'package:flutter_core_project/services/onboarding_service.dart';
import 'package:flutter_core_project/services/auth_service.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Dismiss native splash ngay khi Flutter đã vẽ frame đầu tiên
    // Transition từ native splash → Flutter splash hoàn toàn liền mạch
    FlutterNativeSplash.remove();
    _redirect();
  }

  @override
  Widget build(BuildContext context) {
    // Nền trắng + logo THP ở giữa — khớp hoàn toàn với native splash
    // → không có flash hay chuyển đổi màu khi Flutter vẽ frame đầu tiên
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SvgPicture.asset(
          AppVectors.thp_logo,
          height: 150,
          width: 150,
        ),
      ),
    );
  }

  Future<void> _redirect() async {
    // Check auth và onboarding song song — không delay nhân tạo
    final results = await Future.wait([
      AuthService.isLoggedIn(),
      OnboardingService.hasSeenIntro(),
    ]);

    final isLoggedIn = results[0];

    if (!mounted) return;

    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MainScreen(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const GetStartedPage(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }
}
