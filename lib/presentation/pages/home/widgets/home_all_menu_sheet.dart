import 'package:flutter/material.dart';
import 'package:flutter_core_project/common/helpers/is_dark_mode.dart';
import 'package:flutter_core_project/presentation/intro/pages/get_started.dart';
import 'package:flutter_core_project/presentation/pages/leave_request/leave_request_page.dart';
import 'package:flutter_core_project/presentation/pages/profile/profile_page.dart';
import 'package:flutter_core_project/presentation/pages/request_history/request_history_page.dart';
import 'package:flutter_core_project/presentation/pages/work_schedule/work_schedule_setup_page.dart';
import 'package:flutter_core_project/services/auth_service.dart';
import 'package:flutter_core_project/services/localization_service.dart';

/// Hiển thị bottom sheet tất cả chức năng
void showAllMenuSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AllMenuSheet(),
  );
}

// ---------------------------------------------------------------------------
// Bottom Sheet Widget
// ---------------------------------------------------------------------------
class _AllMenuSheet extends StatefulWidget {
  const _AllMenuSheet();

  @override
  State<_AllMenuSheet> createState() => _AllMenuSheetState();
}

class _AllMenuSheetState extends State<_AllMenuSheet> {
  // ------------------------------------------------------------------
  // Logout helper (tái sử dụng logic từ ProfilePage)
  // ------------------------------------------------------------------
  Future<void> _handleLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(context.tr('profile_logout_title')),
        content: Text(context.tr('profile_logout_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.tr('profile_logout_cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFF44545),
            ),
            child: Text(context.tr('profile_logout')),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await AuthService.logout();
      if (!mounted) return;
      // Đóng bottom sheet trước khi remove toàn bộ stack
      Navigator.pop(context);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const GetStartedPage()),
        (route) => false,
      );
    }
  }

  // ------------------------------------------------------------------
  // Build
  // ------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    final items = _buildItems(context, isDark);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF8F9FA),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag handle ────────────────────────────────────────
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // ── Header ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Text(
                    'Tất cả chức năng',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF111827),
                      fontFamily: 'Satoshi',
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF2A2A2A)
                            : const Color(0xFFEEEEEE),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: isDark
                            ? Colors.white60
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Grid ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 6,
                  childAspectRatio: 0.85,
                ),
                itemCount: items.length,
                itemBuilder: (_, i) =>
                    _SheetMenuItem(item: items[i], isDark: isDark),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // Danh sách item
  // ------------------------------------------------------------------
  List<_SheetItem> _buildItems(BuildContext context, bool isDark) {
    return [
      // ── Từ quick menu ──────────────────────────────────────────
      _SheetItem(
        icon: Icons.description_outlined,
        label: context.tr('menu_documents'),
        iconColor: const Color(0xFF3B82F6),
        bgLight: const Color(0xFFEFF6FF),
        bgDark: const Color(0xFF1E3A5F),
        isComingSoon: true,
      ),
      _SheetItem(
        icon: Icons.calendar_month_outlined,
        label: context.tr('menu_work_schedule'),
        iconColor: const Color(0xFF8B5CF6),
        bgLight: const Color(0xFFF5F3FF),
        bgDark: const Color(0xFF2E1B5E),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const WorkScheduleSetupPage()),
          );
        },
      ),
      _SheetItem(
        icon: Icons.account_balance_wallet_outlined,
        label: context.tr('menu_payroll'),
        iconColor: const Color(0xFFF59E0B),
        bgLight: const Color(0xFFFFFBEB),
        bgDark: const Color(0xFF422006),
        isComingSoon: true,
      ),
      _SheetItem(
        icon: Icons.info_outline_rounded,
        label: context.tr('menu_info'),
        iconColor: const Color(0xFF10B981),
        bgLight: const Color(0xFFECFDF5),
        bgDark: const Color(0xFF064E3B),
      ),

      // ── Chức năng mới ──────────────────────────────────────────
      _SheetItem(
        icon: Icons.event_busy_outlined,
        label: 'Xin nghỉ phép',
        iconColor: const Color(0xFFEC4899),
        bgLight: const Color(0xFFFDF2F8),
        bgDark: const Color(0xFF500724),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LeaveRequestPage()),
          );
        },
      ),
      const _SheetItem(
        icon: Icons.folder_outlined,
        label: 'Tài liệu',
        iconColor: Color(0xFFF97316),
        bgLight: Color(0xFFFFF7ED),
        bgDark: Color(0xFF431407),
        isComingSoon: true,
      ),
      _SheetItem(
        icon: Icons.history_outlined,
        label: context.tr('menu_request_history'),
        iconColor: const Color(0xFF0EA5E9),
        bgLight: const Color(0xFFE0F2FE),
        bgDark: const Color(0xFF0C4A6E),
        onTap: () {
          Navigator.pop(context); // đóng bottom sheet
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RequestHistoryPage()),
          );
        },
      ),
      _SheetItem(
        icon: Icons.settings_outlined,
        label: 'Cài đặt',
        iconColor: const Color(0xFF6B7280),
        bgLight: const Color(0xFFF3F4F6),
        bgDark: const Color(0xFF1F2937),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsPage()),
          );
        },
      ),
      _SheetItem(
        icon: Icons.logout_rounded,
        label: 'Đăng xuất',
        iconColor: const Color(0xFFEF4444),
        bgLight: const Color(0xFFFFF1F2),
        bgDark: const Color(0xFF4C0519),
        onTap: _handleLogout,
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
// Single menu item widget
// ---------------------------------------------------------------------------
class _SheetMenuItem extends StatelessWidget {
  final _SheetItem item;
  final bool isDark;

  const _SheetMenuItem({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? item.bgDark : item.bgLight;

    return GestureDetector(
      onTap: item.isComingSoon ? null : item.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon box + badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: item.iconColor
                          .withOpacity(isDark ? 0.22 : 0.13),
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(item.icon, color: item.iconColor, size: 25),
                ),
              ),
              // Dim overlay
              if (item.isComingSoon)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withOpacity(0.38)
                          : Colors.white.withOpacity(0.50),
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              // "Sắp ra mắt" badge — canh giữa phía trên, màu trầm
              if (item.isComingSoon)
                Positioned(
                  top: -9,
                  left: 0,
                  right: 0,
                  child: Center(
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
                          fontSize: 7,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          // fontFamily: 'Satoshi',
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 7),
          SizedBox(
            width: 64,
            child: Text(
              item.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isDark
                    ? const Color(0xFFBEBEBE)
                    : const Color(0xFF374151),
                // fontFamily: 'Satoshi',
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Data class
// ---------------------------------------------------------------------------
class _SheetItem {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color bgLight;
  final Color bgDark;
  final bool isComingSoon;
  final VoidCallback? onTap;

  const _SheetItem({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.bgLight,
    required this.bgDark,
    this.isComingSoon = false,
    this.onTap,
  });
}

