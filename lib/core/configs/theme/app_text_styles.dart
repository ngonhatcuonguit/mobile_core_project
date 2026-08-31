// ─────────────────────────────────────────────────────────────────────────────
// AppTextStyles — Tập trung toàn bộ text style cho app.
//
// Font chữ: Be Vietnam Pro
//   • Hỗ trợ đầy đủ tiếng Việt (có dấu) lẫn tiếng Anh.
//   • Thiết kế hiện đại, dễ đọc trên màn hình nhỏ.
//
// Cách dùng:
//   Text('Xin chào', style: AppTextStyles.h1)
//   Text('Nội dung', style: AppTextStyles.bodyMedium)
//   Text('Nhỏ', style: AppTextStyles.labelSmall.copyWith(color: Colors.red))
//
// Để thay font toàn app: chỉ cần đổi [_fontFamily] bên dưới.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

class AppTextStyles {
  AppTextStyles._();

  // ── Font family duy nhất — đổi ở đây là đổi toàn app ──────────────────────
  static const String fontFamily = 'BeVietnamPro';

  // ── Helpers ────────────────────────────────────────────────────────────────
  static TextStyle _base({
    required double fontSize,
    required FontWeight fontWeight,
    double? height,
    FontStyle fontStyle = FontStyle.normal,
    double? letterSpacing,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        fontStyle: fontStyle,
        letterSpacing: letterSpacing,
      );

  // ── Headings ───────────────────────────────────────────────────────────────
  /// 28sp · Bold · cho tiêu đề màn hình lớn
  static final TextStyle h1 =
      _base(fontSize: 28, fontWeight: FontWeight.w700, height: 1.3);

  /// 24sp · Bold · cho tiêu đề section chính
  static final TextStyle h2 =
      _base(fontSize: 24, fontWeight: FontWeight.w700, height: 1.35);

  /// 20sp · SemiBold · tiêu đề card / sheet
  static final TextStyle h3 =
      _base(fontSize: 20, fontWeight: FontWeight.w600, height: 1.4);

  /// 18sp · SemiBold · AppBar title / dialog title
  static final TextStyle h4 =
      _base(fontSize: 18, fontWeight: FontWeight.w600, height: 1.4);

  /// 16sp · SemiBold · sub-title, section header
  static final TextStyle h5 =
      _base(fontSize: 16, fontWeight: FontWeight.w600, height: 1.45);

  /// 14sp · SemiBold · card title, list item title
  static final TextStyle h6 =
      _base(fontSize: 14, fontWeight: FontWeight.w600, height: 1.5);

  // ── Body ───────────────────────────────────────────────────────────────────
  /// 16sp · Regular · nội dung chính
  static final TextStyle bodyLarge =
      _base(fontSize: 16, fontWeight: FontWeight.w400, height: 1.55);

  /// 14sp · Regular · nội dung cơ bản (default)
  static final TextStyle bodyMedium =
      _base(fontSize: 14, fontWeight: FontWeight.w400, height: 1.55);

  /// 12sp · Regular · nội dung phụ, caption
  static final TextStyle bodySmall =
      _base(fontSize: 12, fontWeight: FontWeight.w400, height: 1.5);

  // ── Medium variants ────────────────────────────────────────────────────────
  /// 16sp · Medium
  static final TextStyle bodyLargeMedium =
      _base(fontSize: 16, fontWeight: FontWeight.w500, height: 1.55);

  /// 14sp · Medium — dùng nhiều nhất cho label / hint
  static final TextStyle bodyMediumMedium =
      _base(fontSize: 14, fontWeight: FontWeight.w500, height: 1.55);

  /// 12sp · Medium
  static final TextStyle bodySmallMedium =
      _base(fontSize: 12, fontWeight: FontWeight.w500, height: 1.5);

  // ── Label / Caption ────────────────────────────────────────────────────────
  /// 13sp · Medium · navigation label, tab label
  static final TextStyle labelMedium =
      _base(fontSize: 13, fontWeight: FontWeight.w500, height: 1.4);

  /// 11sp · Medium · badge, chip
  static final TextStyle labelSmall = _base(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      height: 1.3,
      letterSpacing: 0.2);

  /// 10sp · Bold · micro label, status tag
  static final TextStyle labelTiny = _base(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: 0.3);

  // ── Button ─────────────────────────────────────────────────────────────────
  /// 16sp · SemiBold · primary button
  static final TextStyle button = _base(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: 0.2);

  /// 14sp · SemiBold · secondary / small button
  static final TextStyle buttonSmall = _base(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: 0.1);

  // ── Input / Form ───────────────────────────────────────────────────────────
  /// 14sp · Regular · input text
  static final TextStyle input =
      _base(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);

  /// 14sp · Regular · hint text
  static final TextStyle hint =
      _base(fontSize: 14, fontWeight: FontWeight.w400, height: 1.5);

  // ── Numeric / Mono-spaced feel ─────────────────────────────────────────────
  /// 24sp · Bold · số lớn (giờ công, lương…)
  static final TextStyle numberLarge =
      _base(fontSize: 24, fontWeight: FontWeight.w700, height: 1.2);

  /// 18sp · SemiBold · số vừa
  static final TextStyle numberMedium =
      _base(fontSize: 18, fontWeight: FontWeight.w600, height: 1.25);

  /// 14sp · SemiBold · số nhỏ (badge, counter)
  static final TextStyle numberSmall =
      _base(fontSize: 14, fontWeight: FontWeight.w600, height: 1.2);

  // ── Italic ─────────────────────────────────────────────────────────────────
  /// 14sp · Italic · chú thích, ghi chú
  static final TextStyle italic = _base(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.italic,
      height: 1.5);
}
