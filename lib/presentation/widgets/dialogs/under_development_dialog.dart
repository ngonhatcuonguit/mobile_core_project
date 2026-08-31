import 'package:flutter/material.dart';
import 'package:flutter_core_project/common/helpers/is_dark_mode.dart';

/// Hiển thị dialog "Chức năng đang được phát triển"
void showUnderDevelopmentDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => const _UnderDevelopmentDialog(),
  );
}

class _UnderDevelopmentDialog extends StatelessWidget {
  const _UnderDevelopmentDialog();

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      title: Row(
        children: [
          const Icon(Icons.construction_rounded,
              color: Color(0xFFFFA500), size: 24),
          const SizedBox(width: 12),
          Text(
            'Chức năng đang được phát triển',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF111827),
            ),
          ),
        ],
      ),
      content: Text(
        'Tính năng này đang được phát triển.\nVui lòng quay lại sau!',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: isDark ? const Color(0xFFBEBEBE) : const Color(0xFF6B7280),
          height: 1.5,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Đóng',
            style: TextStyle(
              color: isDark ? const Color(0xFF42C83C) : const Color(0xFF42C83C),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
