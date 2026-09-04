import 'package:flutter/material.dart';
import 'package:flutter_core_project/core/configs/theme/app_colors.dart';

class GradientAppButton extends StatelessWidget {
  const GradientAppButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.icon,
    this.height = 52,
    this.borderRadius = 8,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Widget? icon;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final radius = BorderRadius.circular(borderRadius);
    final textStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        );

    Widget content = child;
    if (icon != null) {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          const SizedBox(width: 8),
          Flexible(child: child),
        ],
      );
    }

    return Semantics(
      button: true,
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: Ink(
            height: height,
            decoration: BoxDecoration(
              borderRadius: radius,
              gradient: enabled ? AppColors.buttonGradientFor(context) : null,
              color: enabled
                  ? null
                  : Theme.of(context).disabledColor.withValues(alpha: 0.14),
            ),
            child: InkWell(
              onTap: onPressed,
              child: Padding(
                padding: padding,
                child: Center(
                  child: IconTheme.merge(
                    data: const IconThemeData(color: Colors.white),
                    child: DefaultTextStyle.merge(
                      style: textStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      child: content,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
