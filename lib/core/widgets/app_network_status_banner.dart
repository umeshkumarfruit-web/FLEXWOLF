import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flutter/material.dart';

class AppNetworkStatusBanner extends StatelessWidget {
  const AppNetworkStatusBanner({
    required this.message,
    this.status = AppNetworkStatus.neutral,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String message;
  final AppNetworkStatus status;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = switch (status) {
      AppNetworkStatus.neutral => (AppColors.neutral100, AppColors.textPrimary),
      AppNetworkStatus.offline => (AppColors.neutral900, AppColors.textInverse),
      AppNetworkStatus.stale => (AppColors.warning, AppColors.textInverse),
      AppNetworkStatus.recovered => (AppColors.success, AppColors.textInverse),
    };
    final semanticMessage = message.endsWith('.') ? message : '$message.';
    final semanticLabel = actionLabel == null
        ? semanticMessage
        : '$semanticMessage $actionLabel';

    return Semantics(
      container: true,
      liveRegion: true,
      label: semanticLabel,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: AppTouchTargets.minimum),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colors.$1,
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: Row(
          children: [
            Icon(_iconFor(status), color: colors.$2, size: AppIconSizes.sm),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodySmall.copyWith(color: colors.$2),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(width: AppSpacing.sm),
              TextButton(
                onPressed: onAction,
                child: Text(
                  actionLabel!,
                  style: AppTypography.cta.copyWith(color: colors.$2),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconFor(AppNetworkStatus status) {
    return switch (status) {
      AppNetworkStatus.neutral => Icons.info_outline,
      AppNetworkStatus.offline => Icons.wifi_off_outlined,
      AppNetworkStatus.stale => Icons.history,
      AppNetworkStatus.recovered => Icons.check_circle_outline,
    };
  }
}

enum AppNetworkStatus { neutral, offline, stale, recovered }
