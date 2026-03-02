import 'package:flutter/material.dart';
import 'package:flutter_core_project/core/configs/assets/app_vectors.dart';
import 'package:flutter_core_project/presentation/intro/pages/get_started.dart';
import 'package:flutter_core_project/presentation/pages/main/main_screen.dart';
import 'package:flutter_core_project/services/onboarding_service.dart';
import 'package:flutter_core_project/services/auth_service.dart';
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
    redirect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SvgPicture.asset(
          AppVectors.thp_logo,
          height: 150,
          width: 150,
        ),
      ),
    );
  }

  Future<void> redirect() async {
    await Future.delayed(const Duration(seconds: 2));

    // Check authentication and onboarding status
    final hasSeenIntro = await OnboardingService.hasSeenIntro();
    final isLoggedIn = await AuthService.isLoggedIn();

    if (!mounted) return;

    // Flow logic:
    // 1. If user is logged in -> go to MainScreen (home)
    // 2. If user has seen intro but not logged in -> go to GetStartedPage
    // 3. If first time user -> go to GetStartedPage

    if (isLoggedIn) {
      // User is logged in, go directly to home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else if (hasSeenIntro) {
      // User has seen intro but not logged in, show get started
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const GetStartedPage()),
      );
    } else {
      // First time user, show intro
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const GetStartedPage()),
      );
    }
  }
}
