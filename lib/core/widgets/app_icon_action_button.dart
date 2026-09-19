import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flutter/material.dart';

class AppIconActionButton extends StatelessWidget {
  const AppIconActionButton({
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.tooltip,
    this.isSelected = false,
    super.key,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      selected: isSelected,
      label: semanticLabel,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip ?? semanticLabel,
        isSelected: isSelected,
        constraints: const BoxConstraints(
          minWidth: AppTouchTargets.minimum,
          minHeight: AppTouchTargets.minimum,
        ),
        icon: Icon(icon, size: AppIconSizes.md),
      ),
    );
  }
}
