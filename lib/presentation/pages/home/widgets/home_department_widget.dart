import 'package:flutter/material.dart';
import 'package:flutter_core_project/common/helpers/is_dark_mode.dart';
import 'package:flutter_core_project/services/localization_service.dart';

class HomeDepartmentWidget extends StatelessWidget {
  const HomeDepartmentWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    final departments = [
      _DepartmentItem(
        code: 'BOM',
        name: context.tr('dept_bom'),
        icon: Icons.groups_2_outlined,
        iconColor: const Color(0xFF8B5CF6),
        bgLight: const Color(0xFFF5F3FF),
        bgDark: const Color(0xFF2E1B5E),
        isComingSoon: true,
      ),
      _DepartmentItem(
        code: 'IT',
        name: context.tr('dept_it'),
        icon: Icons.computer_outlined,
        iconColor: const Color(0xFF3B82F6),
        bgLight: const Color(0xFFEFF6FF),
        bgDark: const Color(0xFF1E3A5F),
      ),
      _DepartmentItem(
        code: 'HR',
        name: context.tr('dept_hr'),
        icon: Icons.manage_search_outlined,
        iconColor: const Color(0xFF10B981),
        bgLight: const Color(0xFFECFDF5),
        bgDark: const Color(0xFF064E3B),
      ),
      _DepartmentItem(
        code: 'Logistics',
        name: context.tr('dept_logistics'),
        icon: Icons.local_shipping_outlined,
        iconColor: const Color(0xFFF59E0B),
        bgLight: const Color(0xFFFFFBEB),
        bgDark: const Color(0xFF422006),
        isComingSoon: true,
      ),
      _DepartmentItem(
        code: 'Consumer',
        name: context.tr('dept_consumer'),
        icon: Icons.shopping_cart_outlined,
        iconColor: const Color(0xFFEF4444),
        bgLight: const Color(0xFFFFF1F2),
        bgDark: const Color(0xFF4C0519),
        isComingSoon: true,
      ),
      _DepartmentItem(
        code: 'Legal',
        name: context.tr('dept_legal'),
        icon: Icons.gavel_outlined,
        iconColor: const Color(0xFF0EA5E9),
        bgLight: const Color(0xFFE0F2FE),
        bgDark: const Color(0xFF0C4A6E),
        isComingSoon: true,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                context.tr('home_departments'),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                  fontFamily: 'Satoshi',
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  context.tr('home_see_all'),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF42C83C),
                    fontFamily: 'Satoshi',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
          Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4, // ↓ was 1.6 — taller cards to prevent overflow on small screens
            ),
            itemCount: departments.length,
            itemBuilder: (_, i) =>
                _DepartmentCard(item: departments[i], isDark: isDark),
          ),
        ),
      ],
    );
  }
}

class _DepartmentCard extends StatelessWidget {
  final _DepartmentItem item;
  final bool isDark;
  const _DepartmentCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.isComingSoon ? null : () {},
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Main card — fill toàn bộ cell GridView
          Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? item.bgDark : item.bgLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.iconColor,
                    size: 20,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.code,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF111827),
                        fontFamily: 'Satoshi',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: isDark
                            ? Colors.white38
                            : const Color(0xFF6B7280),
                        fontFamily: 'Satoshi',
                      ),
                    ),
                  ],
                ),
              ],
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
          // "Sắp ra mắt" badge — top-right, 1 dòng, màu trầm
          if (item.isComingSoon)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF64748B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Sắp ra mắt',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'Satoshi',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DepartmentItem {
  final String code;
  final String name;
  final IconData icon;
  final Color iconColor;
  final Color bgLight;
  final Color bgDark;
  final bool isComingSoon;

  const _DepartmentItem({
    required this.code,
    required this.name,
    required this.icon,
    required this.iconColor,
    required this.bgLight,
    required this.bgDark,
    this.isComingSoon = false,
  });
}
