import 'package:flutter/material.dart';
import 'package:flutter_core_project/common/helpers/is_dark_mode.dart';

class HomeQuickMenuWidget extends StatelessWidget {
  const HomeQuickMenuWidget({super.key});

  static const List<_MenuItem> _menuItems = [
    _MenuItem(icon: Icons.description_outlined, label: 'Giấy tờ'),
    _MenuItem(icon: Icons.calendar_month_outlined, label: 'NghỉTphép'),
    _MenuItem(icon: Icons.account_balance_wallet_outlined, label: 'Bảng\nLương'),
    _MenuItem(icon: Icons.info_outline_rounded, label: 'Thông tin'),
    _MenuItem(icon: Icons.apps_rounded, label: 'See All'),
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
    final bgColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F0F0);

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
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                item.icon,
                color: const Color(0xFF42C83C),
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
  final IconData icon;
  final String label;

  const _MenuItem({required this.icon, required this.label});
}
