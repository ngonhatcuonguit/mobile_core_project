import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_core_project/common/helpers/is_dark_mode.dart';
import 'package:flutter_core_project/services/localization_service.dart';
import 'package:flutter_core_project/presentation/pages/home/widgets/home_all_menu_sheet.dart';
import 'package:flutter_core_project/presentation/pages/work_schedule/work_schedule_setup_page.dart';

class HomeQuickMenuWidget extends StatelessWidget {
  const HomeQuickMenuWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    final menuItems = [
      _MenuItem(
        icon: Icons.description_outlined,
        label: context.tr('menu_documents'),
        iconColor: const Color(0xFF3B82F6),
        bgLight: const Color(0xFFEFF6FF),
        bgDark: const Color(0xFF1E3A5F),
        isComingSoon: true,
      ),
      _MenuItem(
        icon: Icons.calendar_month_outlined,
        label: context.tr('menu_work_schedule'),
        iconColor: const Color(0xFF8B5CF6),
        bgLight: const Color(0xFFF5F3FF),
        bgDark: const Color(0xFF2E1B5E),
      ),
      _MenuItem(
        icon: Icons.account_balance_wallet_outlined,
        label: context.tr('menu_payroll'),
        iconColor: const Color(0xFFF59E0B),
        bgLight: const Color(0xFFFFFBEB),
        bgDark: const Color(0xFF422006),
        isComingSoon: true,
      ),
      _MenuItem(
        icon: Icons.info_outline_rounded,
        label: context.tr('menu_info'),
        iconColor: const Color(0xFF10B981),
        bgLight: const Color(0xFFECFDF5),
        bgDark: const Color(0xFF064E3B),
      ),
      _MenuItem(
        icon: Icons.apps_rounded,
        label: context.tr('menu_see_all'),
        iconColor: const Color(0xFFEF4444),
        bgLight: const Color(0xFFFFF1F2),
        bgDark: const Color(0xFF4C0519),
      ),
    ];

    final menuTaps = <VoidCallback?>[
      null, // documents
      // work schedule
      () => Navigator.of(context).push(
        MaterialPageRoute(
            builder: (_) => const WorkScheduleSetupPage()),
      ),

      null, // payroll
      null, // info
      () => showAllMenuSheet(context), // see all
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(
          menuItems.length,
          (i) => _QuickMenuItem(
              item: menuItems[i], isDark: isDark, onTap: menuTaps[i]),
        ),
      ),
    );
  }
}

class _QuickMenuItem extends StatelessWidget {
  final _MenuItem item;
  final bool isDark;
  final VoidCallback? onTap;

  const _QuickMenuItem(
      {required this.item, required this.isDark, this.onTap});

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? item.bgDark : item.bgLight;

    return GestureDetector(
      onTap: item.isComingSoon ? null : onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: item.iconColor.withOpacity(isDark ? 0.25 : 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: item.icon is String
                      ? SvgPicture.asset(
                          item.icon as String,
                          width: 26,
                          height: 26,
                          colorFilter: ColorFilter.mode(
                            item.iconColor,
                            BlendMode.srcIn,
                          ),
                        )
                      : Icon(
                          item.icon as IconData,
                          color: item.iconColor,
                          size: 26,
                        ),
                ),
              ),
              // Dim overlay for coming soon
              if (item.isComingSoon)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withOpacity(0.38)
                          : Colors.white.withOpacity(0.50),
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              // "Sắp ra mắt" badge — lệch phải, màu trầm
              if (item.isComingSoon)
                Positioned(
                  top: -9,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF64748B),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Sắp ra mắt',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontFamily: 'Satoshi',
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 7),
          SizedBox(
            width: 62,
            child: Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFFBEBEBE) : const Color(0xFF374151),
                fontFamily: 'Satoshi',
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final dynamic icon;
  final String label;
  final Color iconColor;
  final Color bgLight;
  final Color bgDark;
  final bool isComingSoon;

  _MenuItem({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.bgLight,
    required this.bgDark,
    this.isComingSoon = false,
  });
}
