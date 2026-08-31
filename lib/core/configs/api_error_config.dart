import 'package:flutter/material.dart';

/// Callback xử lý khi user nhấn nút action trong dialog lỗi.
/// [ctx] là context của chính dialog đó.
typedef ApiErrorActionCallback = Future<void> Function(BuildContext ctx);

// ─────────────────────────────────────────────────────────────────────────────
// Model: một nút action trong dialog
// ─────────────────────────────────────────────────────────────────────────────

/// Cấu hình một nút bấm trong error dialog.
class ApiErrorActionConfig {
  final String label;

  /// Màu nền nút. Nếu null → dùng màu mặc định theo theme.
  final Color? backgroundColor;

  /// Màu chữ nút. Nếu null → tự suy ra từ [backgroundColor].
  final Color? foregroundColor;

  /// Hành động khi nhấn nút.
  /// Nếu null → mặc định đóng dialog (`Navigator.of(ctx).pop()`).
  final ApiErrorActionCallback? onPressed;

  const ApiErrorActionConfig({
    required this.label,
    this.backgroundColor,
    this.foregroundColor,
    this.onPressed,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Model: toàn bộ dialog cho một loại lỗi
// ─────────────────────────────────────────────────────────────────────────────

/// Cấu hình toàn bộ error dialog cho một HTTP status code cụ thể.
class ApiErrorDialogConfig {
  final IconData icon;
  final Color iconColor;
  final String title;

  /// Message mặc định hiển thị khi server không trả về message cụ thể.
  final String? defaultMessage;

  /// Tuỳ chỉnh message dựa trên nội dung server trả về.
  /// Nếu null → dùng [defaultMessage] hoặc server message trực tiếp.
  final String Function(String? serverMessage)? messageBuilder;

  final List<ApiErrorActionConfig> actions;

  const ApiErrorDialogConfig({
    this.icon = Icons.error_outline_rounded,
    this.iconColor = const Color(0xFFE53935),
    required this.title,
    this.defaultMessage,
    this.messageBuilder,
    required this.actions,
  });

  /// Lấy message để hiển thị: ưu tiên [messageBuilder] → server message → [defaultMessage].
  String resolveMessage(String? serverMessage) {
    if (messageBuilder != null) return messageBuilder!(serverMessage);
    return serverMessage ??
        defaultMessage ??
        'Đã có lỗi xảy ra. Vui lòng thử lại.';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Registry trung tâm
// ─────────────────────────────────────────────────────────────────────────────

/// Registry ánh xạ HTTP status code → [ApiErrorDialogConfig].
///
/// Để thêm / thay đổi config, gọi [ApiErrorConfigs.register] trong quá trình
/// khởi động app — thường trong [setupApiErrorConfigs()] ở injection_container.
///
/// ```dart
/// ApiErrorConfigs.register(401, ApiErrorDialogConfig(
///   title: 'Phiên hết hạn',
///   actions: [...],
/// ));
/// ```
class ApiErrorConfigs {
  ApiErrorConfigs._();

  static final Map<int, ApiErrorDialogConfig> _configs = {};

  /// Config dự phòng khi không tìm thấy config cho status code đó.
  static ApiErrorDialogConfig fallback = const ApiErrorDialogConfig(
    icon: Icons.cloud_off_rounded,
    iconColor: Color(0xFFE53935),
    title: 'Lỗi',
    defaultMessage: 'Đã có lỗi xảy ra. Vui lòng thử lại.',
    actions: [ApiErrorActionConfig(label: 'Đóng')],
  );

  /// Đăng ký (hoặc ghi đè) config cho một HTTP status code.
  static void register(int statusCode, ApiErrorDialogConfig config) {
    _configs[statusCode] = config;
  }

  /// Lấy config theo status code. Trả về `null` nếu chưa đăng ký.
  static ApiErrorDialogConfig? get(int statusCode) => _configs[statusCode];

  /// Lấy config theo status code. Trả về [fallback] nếu chưa đăng ký.
  static ApiErrorDialogConfig getOrFallback(int statusCode) =>
      _configs[statusCode] ?? fallback;

  /// Xoá tất cả config đã đăng ký (dùng cho testing).
  static void clear() => _configs.clear();
}
