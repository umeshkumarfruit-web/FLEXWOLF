import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flutter/material.dart';

class AppBadge extends StatelessWidget {
  const AppBadge({
    required this.label,
    this.tone = AppBadgeTone.neutral,
    super.key,
  });

  final String label;
  final AppBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      AppBadgeTone.neutral => (AppColors.black, AppColors.white),
      AppBadgeTone.sale => (AppColors.sale, AppColors.white),
      AppBadgeTone.success => (AppColors.success, AppColors.white),
    };

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: colors.$1,
          borderRadius: BorderRadius.circular(AppRadii.xs),
        ),
        child: ExcludeSemantics(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.label.copyWith(color: colors.$2),
          ),
        ),
      ),
    );
  }
}

enum AppBadgeTone { neutral, sale, success }
