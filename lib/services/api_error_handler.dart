import 'package:flutter/material.dart';
import 'package:flutter_core_project/core/configs/api_error_config.dart';
import 'package:flutter_core_project/services/navigation_service.dart';

/// Xử lý và hiển thị dialog lỗi API một cách tập trung.
///
/// Sử dụng [NavigationService.navigatorKey] để show dialog mà không cần
/// [BuildContext] trực tiếp — có thể gọi từ Dio interceptor, service, …
///
/// Config của từng loại lỗi được đăng ký qua [ApiErrorConfigs.register].
class ApiErrorHandler {
  ApiErrorHandler._();

  /// Flag tránh show nhiều dialog chồng nhau cùng lúc.
  static bool _isShowingDialog = false;

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Hiển thị dialog dựa trên HTTP status code.
  ///
  /// [statusCode]     — HTTP status code (401, 403, 500, …)
  /// [serverMessage]  — Message trích xuất từ response body (nếu có)
  static void handleHttpError(
    int statusCode, {
    String? serverMessage,
  }) {
    _show(
      config: ApiErrorConfigs.getOrFallback(statusCode),
      serverMessage: serverMessage,
    );
  }

  /// Hiển thị dialog cho lỗi mạng / timeout (không có HTTP status code).
  ///
  /// [title]   — tiêu đề dialog
  /// [message] — nội dung mô tả lỗi
  static void handleNetworkError({
    String title = 'Lỗi kết nối',
    String message = 'Không thể kết nối đến máy chủ. Kiểm tra mạng và thử lại.',
  }) {
    _show(
      config: ApiErrorDialogConfig(
        icon: Icons.wifi_off_rounded,
        iconColor: const Color(0xFFF57C00),
        title: title,
        defaultMessage: message,
        actions: const [ApiErrorActionConfig(label: 'Đóng')],
      ),
    );
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  static void _show({
    required ApiErrorDialogConfig config,
    String? serverMessage,
  }) {
    if (_isShowingDialog) return;

    final context = NavigationService.context;
    if (context == null) return;

    _isShowingDialog = true;

    // Đợi frame kế để tránh xung đột khi gọi từ interceptor
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = NavigationService.context;
      if (ctx == null) {
        _isShowingDialog = false;
        return;
      }
      showDialog<void>(
        context: ctx,
        barrierDismissible: false,
        builder: (dialogCtx) =>
            _ApiErrorDialog(config: config, serverMessage: serverMessage),
      ).whenComplete(() => _isShowingDialog = false);
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget nội bộ: Dialog UI
// ─────────────────────────────────────────────────────────────────────────────

class _ApiErrorDialog extends StatelessWidget {
  final ApiErrorDialogConfig config;
  final String? serverMessage;

  const _ApiErrorDialog({
    required this.config,
    this.serverMessage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
    final labelColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: cardColor,
      contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 4),
      actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Icon circle ───────────────────────────────────────────────────
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: config.iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(config.icon, color: config.iconColor, size: 38),
          ),
          const SizedBox(height: 16),

          // ── Title ─────────────────────────────────────────────────────────
          Text(
            config.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),

          // ── Message ───────────────────────────────────────────────────────
          Text(
            config.resolveMessage(serverMessage),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: labelColor, height: 1.5),
          ),
          const SizedBox(height: 4),
        ],
      ),
      actions: config.actions.map((action) {
        return _buildActionButton(context, action, isDark);
      }).toList(),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    ApiErrorActionConfig action,
    bool isDark,
  ) {
    final hasBg = action.backgroundColor != null;
    final bgColor = action.backgroundColor ??
        (isDark ? const Color(0xFF3A3A3A) : Colors.grey[200]!);
    final fgColor = action.foregroundColor ??
        (hasBg ? Colors.white : (isDark ? Colors.grey[300]! : Colors.grey[800]!));

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: SizedBox(
        width: double.infinity,
        child: TextButton(
          style: TextButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: fgColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 13),
          ),
          onPressed: () async {
            if (action.onPressed != null) {
              await action.onPressed!(context);
            } else {
              Navigator.of(context).pop();
            }
          },
          child: Text(
            action.label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

