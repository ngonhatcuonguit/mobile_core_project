import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_core_project/common/helpers/is_dark_mode.dart';

class HomeQuickMenuWidget extends StatelessWidget {
  const HomeQuickMenuWidget({super.key});

  static const List<_MenuItem> _menuItems = [
    _MenuItem(
      icon: Icons.description_outlined,
      label: 'Giấy tờ',
      iconColor: Color(0xFF3B82F6), // xanh dương
      bgLight: Color(0xFFEFF6FF),
      bgDark: Color(0xFF1E3A5F),
    ),
    _MenuItem(
      icon: Icons.calendar_month_outlined,
      label: 'Nghỉ phép',
      iconColor: Color(0xFF8B5CF6), // tím
      bgLight: Color(0xFFF5F3FF),
      bgDark: Color(0xFF2E1B5E),
    ),
    _MenuItem(
      icon: Icons.account_balance_wallet_outlined,
      label: 'Bảng lương',
      iconColor: Color(0xFFF59E0B), // cam vàng
      bgLight: Color(0xFFFFFBEB),
      bgDark: Color(0xFF422006),
    ),
    _MenuItem(
      icon: Icons.info_outline_rounded,
      label: 'Thông tin',
      iconColor: Color(0xFF10B981), // xanh teal
      bgLight: Color(0xFFECFDF5),
      bgDark: Color(0xFF064E3B),
    ),
    _MenuItem(
      icon: Icons.apps_rounded,
      label: 'See All',
      iconColor: Color(0xFFEF4444), // đỏ hồng
      bgLight: Color(0xFFFFF1F2),
      bgDark: Color(0xFF4C0519),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _menuItems
            .map((item) => _QuickMenuItem(item: item, isDark: isDark))
            .toList(),
      ),
    );
  }
}

class _QuickMenuItem extends StatelessWidget {
  final _MenuItem item;
  final bool isDark;

  const _QuickMenuItem({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? item.bgDark : item.bgLight;

    return GestureDetector(
      onTap: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
  final dynamic icon; // IconData hoặc String (SVG path)
  final String label;
  final Color iconColor;
  final Color bgLight;
  final Color bgDark;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.bgLight,
    required this.bgDark,
  });
}
