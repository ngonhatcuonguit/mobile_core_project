import 'package:flutter/material.dart';
import 'package:flutter_core_project/common/helpers/is_dark_mode.dart';
import 'package:flutter_core_project/presentation/pages/leave_request/leave_request_page.dart';
import 'package:flutter_core_project/services/localization_service.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ServicePage extends StatefulWidget {
  const ServicePage({super.key});

  @override
  State<ServicePage> createState() => _ServicePageState();
}

class _ServicePageState extends State<ServicePage> {
  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    final services = [
      _ServiceItem(
        key: 'service_achievement',
        icon: 'assets/vectors/ic_performance.svg',
        bgColor: const Color(0xFFFFF0E6),
        bgColorDark: const Color(0xFF4A2E1F),
        accentColor: const Color(0xFFF97316),
      ),
      _ServiceItem(
        key: 'service_leave_request',
        icon: 'assets/vectors/ic_leave.svg',
        bgColor: const Color(0xFFEFF6FF),
        bgColorDark: const Color(0xFF1E3A5F),
        accentColor: const Color(0xFF3B82F6),
        action: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LeaveRequestPage()),
          );
        },
      ),
      _ServiceItem(
        key: 'service_feedback',
        icon: 'assets/vectors/ic_message.svg',
        bgColor: const Color(0xFFF5F3FF),
        bgColorDark: const Color(0xFF2E1B5E),
        accentColor: const Color(0xFF8B5CF6),
      ),
      _ServiceItem(
        key: 'service_organization',
        icon: 'assets/vectors/ic_org.svg',
        bgColor: const Color(0xFFECFDF5),
        bgColorDark: const Color(0xFF064E3B),
        accentColor: const Color(0xFF10B981),
      ),
      _ServiceItem(
        key: 'service_timesheet',
        icon: 'assets/vectors/ic_calender.svg',
        bgColor: const Color(0xFFFFF1F2),
        bgColorDark: const Color(0xFF4C0519),
        accentColor: const Color(0xFFEF4444),
      ),
      _ServiceItem(
        key: 'service_documents',
        icon: 'assets/vectors/ic_file.svg',
        bgColor: const Color(0xFFE0F2FE),
        bgColorDark: const Color(0xFF0C4A6E),
        accentColor: const Color(0xFF0EA5E9),
      ),
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF5F5F5),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Avatar + Title + Bell
              _buildHeader(isDark),
              const SizedBox(height: 24),

              // Services Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.0,
                ),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  final service = services[index];
                  return _ServiceCard(
                    service: service,
                    isDark: isDark,
                    context: context,
                  );
                },
              ),
              const SizedBox(height: 24),

              // Info Banner
              _buildInfoBanner(isDark, context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        // Avatar
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF42C83C),
            border: Border.all(
              color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.person,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        // Title
        Text(
          context.tr('service_title'),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF111827),
          ),
        ),
        const Spacer(),
        // Notification Bell
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.notifications_outlined,
            color: isDark ? Colors.white70 : const Color(0xFF374151),
            size: 20,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBanner(bool isDark, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFA5D6A7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF66BB6A),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: Color(0xFF2E7D32),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.tr('service_info_banner'),
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1B5E20),
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceItem {
  final String key;
  final String icon;
  final Color bgColor;
  final Color bgColorDark;
  final Color accentColor;
  final VoidCallback? action;

  _ServiceItem({
    required this.key,
    required this.icon,
    required this.bgColor,
    required this.bgColorDark,
    required this.accentColor,
    this.action,
  });
}

class _ServiceCard extends StatelessWidget {
  final _ServiceItem service;
  final bool isDark;
  final BuildContext context;

  const _ServiceCard({
    required this.service,
    required this.isDark,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: service.action,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? service.bgColorDark : service.bgColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Container
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: service.accentColor.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: SvgPicture.asset(
                  service.icon,
                  width: 32,
                  height: 32,
                  colorFilter: ColorFilter.mode(
                    service.accentColor,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                context.tr(service.key),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

