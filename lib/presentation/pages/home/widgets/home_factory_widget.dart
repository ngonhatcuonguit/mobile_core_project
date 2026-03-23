import 'package:flutter/material.dart';
import 'package:flutter_core_project/common/helpers/is_dark_mode.dart';

class HomeFactoryWidget extends StatelessWidget {
  const HomeFactoryWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    const factories = [
      _FactoryItem(
        name: 'Nhà máy Bình Dương',
        description: 'Trụ sở chính',
        iconColor: Color(0xFF10B981), // teal — flagship
        bgLight: Color(0xFFECFDF5),
        bgDark: Color(0xFF064E3B),
      ),
      _FactoryItem(
        name: 'Nhà máy Hậu Giang',
        description: 'Khu vực Miền Tây',
        iconColor: Color(0xFF3B82F6), // xanh dương
        bgLight: Color(0xFFEFF6FF),
        bgDark: Color(0xFF1E3A5F),
      ),
      _FactoryItem(
        name: 'Nhà máy Chu Lai',
        description: 'Khu vực Miền Trung',
        iconColor: Color(0xFFF59E0B), // cam vàng
        bgLight: Color(0xFFFFFBEB),
        bgDark: Color(0xFF422006),
      ),
      _FactoryItem(
        name: 'Nhà máy Hà Nam',
        description: 'Khu vực Miền Bắc',
        iconColor: Color(0xFF8B5CF6), // tím
        bgLight: Color(0xFFF5F3FF),
        bgDark: Color(0xFF2E1B5E),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: factories
            .map((f) => _FactoryCard(item: f, isDark: isDark))
            .toList(),
      ),
    );
  }
}

class _FactoryCard extends StatelessWidget {
  final _FactoryItem item;
  final bool isDark;
  const _FactoryCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isDark ? item.bgDark : item.bgLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.factory_outlined,
                color: item.iconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                      fontFamily: 'Satoshi',
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: isDark ? Colors.white38 : const Color(0xFF6B7280),
                      fontFamily: 'Satoshi',
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: isDark ? Colors.white30 : Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _FactoryItem {
  final String name;
  final String description;
  final Color iconColor;
  final Color bgLight;
  final Color bgDark;

  const _FactoryItem({
    required this.name,
    required this.description,
    required this.iconColor,
    required this.bgLight,
    required this.bgDark,
  });
}
