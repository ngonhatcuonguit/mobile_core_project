import 'package:flutter/material.dart';
import 'package:flutter_core_project/presentation/auth/pages/sign_in.dart';
import 'package:flutter_core_project/services/onboarding_service.dart';

class GetStartedPage extends StatelessWidget {
  const GetStartedPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Navigate thẳng đến SigninPage, không cần màn hình intro/choose mode
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await OnboardingService.setIntroSeen();
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SigninPage()),
      );
    });

    // Màn hình trắng tạm trong lúc chuyển trang
    return const Scaffold(
      backgroundColor: Colors.white,
    );
  }
}
