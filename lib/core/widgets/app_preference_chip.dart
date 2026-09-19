import 'package:flexwolf/core/utils/app_haptics.dart';
import 'package:flutter/material.dart';

class AppPreferenceChip extends StatelessWidget {
  const AppPreferenceChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.semanticLabel,
    super.key,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool>? onSelected;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      enabled: onSelected != null,
      label: semanticLabel ?? label,
      child: FilterChip(
        label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        selected: selected,
        showCheckmark: true,
        onSelected: onSelected == null
            ? null
            : (value) {
                AppHaptics.selection();
                onSelected!(value);
              },
      ),
    );
  }
}
