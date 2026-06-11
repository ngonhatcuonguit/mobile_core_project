import 'package:flutter/material.dart';
import 'package:flutter_core_project/common/helpers/is_dark_mode.dart';
import 'package:flutter_core_project/services/localization_service.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final bg = isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF5F6FA);
    final cardBg = isDark ? const Color(0xFF242424) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF111827);
    final textColor = isDark ? Colors.white70 : const Color(0xFF374151);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: cardBg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: titleColor,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.tr('terms_service_title'),
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: titleColor,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('terms_service_heading'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('terms_service_body_1'),
                style: TextStyle(
                  fontSize: 13,
                  color: textColor,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr('terms_service_body_2'),
                style: TextStyle(
                  fontSize: 13,
                  color: textColor,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
