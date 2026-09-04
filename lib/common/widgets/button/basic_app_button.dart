import 'package:flutter/material.dart';
import 'package:flutter_core_project/common/widgets/button/gradient_app_button.dart';

class BasicAppButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String title;
  final double? height;

  const BasicAppButton(
      {super.key, required this.onPressed, required this.title, this.height});

  @override
  Widget build(BuildContext context) {
    return GradientAppButton(
      onPressed: onPressed,
      height: height ?? 80,
      borderRadius: 20,
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
