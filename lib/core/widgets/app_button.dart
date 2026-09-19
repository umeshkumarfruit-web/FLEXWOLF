import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flexwolf/core/utils/app_haptics.dart';
import 'package:flutter/material.dart';

class AppButton extends StatelessWidget {
  const AppButton.primary({
    required this.label,
    required this.onPressed,
    this.icon,
    this.semanticLabel,
    this.enableHaptics = false,
    super.key,
  }) : variant = AppButtonVariant.primary;

  const AppButton.secondary({
    required this.label,
    required this.onPressed,
    this.icon,
    this.semanticLabel,
    this.enableHaptics = false,
    super.key,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.text({
    required this.label,
    required this.onPressed,
    this.icon,
    this.semanticLabel,
    this.enableHaptics = false,
    super.key,
  }) : variant = AppButtonVariant.text;

  const AppButton.filled({
    required this.label,
    required this.onPressed,
    this.icon,
    this.semanticLabel,
    this.enableHaptics = false,
    super.key,
  }) : variant = AppButtonVariant.primary;

  const AppButton.outlined({
    required this.label,
    required this.onPressed,
    this.icon,
    this.semanticLabel,
    this.enableHaptics = false,
    super.key,
  }) : variant = AppButtonVariant.secondary;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? semanticLabel;
  final bool enableHaptics;
  final AppButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = onPressed == null
        ? null
        : () {
            if (enableHaptics) {
              AppHaptics.confirmation();
            }
            onPressed!();
          };

    final child = _ButtonChild(label: label, icon: icon);

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel ?? label,
      child: switch (variant) {
        AppButtonVariant.primary => FilledButton(
          onPressed: effectiveOnPressed,
          child: child,
        ),
        AppButtonVariant.secondary => OutlinedButton(
          onPressed: effectiveOnPressed,
          child: child,
        ),
        AppButtonVariant.text => TextButton(
          onPressed: effectiveOnPressed,
          child: child,
        ),
      },
    );
  }
}

class _ButtonChild extends StatelessWidget {
  const _ButtonChild({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (icon == null) {
      return Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: AppIconSizes.sm),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }
}

enum AppButtonVariant { primary, secondary, text }
