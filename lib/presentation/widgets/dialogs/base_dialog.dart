import 'package:flutter/material.dart';

/// Enum for dialog types
enum DialogType {
  info,
  warning,
  error,
  success,
}

/// Base dialog component for reuse across the app
class BaseDialog extends StatelessWidget {
  final String title;
  final String? message;
  final IconData? icon;
  final Color? iconColor;
  final DialogType type;
  final List<BaseDialogAction>? actions;
  final Widget? customContent;
  final double borderRadius;
  final EdgeInsets contentPadding;
  final bool barrierDismissible;

  const BaseDialog({
    Key? key,
    required this.title,
    this.message,
    this.icon,
    this.iconColor,
    this.type = DialogType.info,
    this.actions,
    this.customContent,
    this.borderRadius = 16,
    this.contentPadding = const EdgeInsets.all(24),
    this.barrierDismissible = true,
  }) : super(key: key);

  /// Get icon based on dialog type
  IconData _getDefaultIcon() {
    switch (type) {
      case DialogType.error:
        return Icons.error_outline;
      case DialogType.warning:
        return Icons.warning_outlined;
      case DialogType.success:
        return Icons.check_circle_outline;
      case DialogType.info:
        return Icons.info_outline;
    }
  }

  /// Get color based on dialog type
  Color _getDefaultColor(BuildContext context) {
    switch (type) {
      case DialogType.error:
        return Colors.red.shade600;
      case DialogType.warning:
        return Colors.orange.shade600;
      case DialogType.success:
        return Colors.green.shade600;
      case DialogType.info:
        return Theme.of(context).primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      contentPadding: contentPadding,
      icon: icon != null || type != DialogType.info
          ? Icon(
              icon ?? _getDefaultIcon(),
              color: iconColor ?? _getDefaultColor(context),
              size: 64,
            )
          : null,
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      content: customContent ??
          (message != null
              ? SingleChildScrollView(
                  child: Text(
                    message!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              : null),
      actions: actions
          ?.map(
            (action) => _buildActionButton(context, action),
          )
          .toList(),
    );
  }

  /// Build action button with styling based on action type
  Widget _buildActionButton(BuildContext context, BaseDialogAction action) {
    final isDestructive = action.isDestructive ?? false;
    final isPrimary = action.isPrimary ?? false;

    if (isPrimary || isDestructive) {
      return ElevatedButton(
        onPressed: action.onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDestructive ? Colors.red : null,
          foregroundColor: isDestructive ? Colors.white : null,
        ),
        child: Text(action.label),
      );
    }

    return TextButton(
      onPressed: action.onPressed,
      child: Text(action.label),
    );
  }
}

/// Dialog action model
class BaseDialogAction {
  final String label;
  final VoidCallback? onPressed;
  final bool? isPrimary;
  final bool? isDestructive;

  BaseDialogAction({
    required this.label,
    this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
  });
}

/// Helper function to show BaseDialog
Future<void> showBaseDialog({
  required BuildContext context,
  required String title,
  String? message,
  IconData? icon,
  Color? iconColor,
  DialogType type = DialogType.info,
  List<BaseDialogAction>? actions,
  Widget? customContent,
  bool barrierDismissible = true,
}) {
  return showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => BaseDialog(
      title: title,
      message: message,
      icon: icon,
      iconColor: iconColor,
      type: type,
      actions: actions,
      customContent: customContent,
      barrierDismissible: barrierDismissible,
    ),
  );
}
