import 'package:flutter/material.dart';
import 'package:flutter_core_project/common/helpers/is_dark_mode.dart';

class HomeDepartmentWidget extends StatelessWidget {
  const HomeDepartmentWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    const departments = [
      _DepartmentItem(
        code: 'BOM',
        name: 'Ban Giám Đốc',
        icon: Icons.groups_2_outlined,
      ),
      _DepartmentItem(
        code: 'IT',
        name: 'Công Nghệ Thông Tin',
        icon: Icons.computer_outlined,
      ),
      _DepartmentItem(
        code: 'HR',
        name: 'Nhân Sự',
        icon: Icons.manage_search_outlined,
      ),
      _DepartmentItem(
        code: 'Logistics',
        name: 'Vận Tải & Kho Bãi',
        icon: Icons.local_shipping_outlined,
      ),
      _DepartmentItem(
        code: 'Consumer',
        name: 'Hàng Tiêu Dùng',
        icon: Icons.shopping_cart_outlined,
      ),
      _DepartmentItem(
        code: 'Legal',
        name: 'Pháp Lý',
        icon: Icons.gavel_outlined,
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
                'Phòng ban',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                  fontFamily: 'Satoshi',
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'Xem tất cả',
                  style: TextStyle(
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
              childAspectRatio: 1.6,
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
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(14),
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
                color: const Color(0xFF42C83C).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                item.icon,
                color: const Color(0xFF42C83C),
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
    );
  }
}

class _DepartmentItem {
  final String code;
  final String name;
  final IconData icon;
  const _DepartmentItem({
    required this.code,
    required this.name,
    required this.icon,
  });
}

