import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/widgets/app_button.dart';
import 'package:flutter/material.dart';

class AppErrorState extends StatelessWidget {
  const AppErrorState({required this.error, this.onRetry, super.key});

  final AppException error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AppRetryState(
      title: error.userMessage,
      message: error.isRetryable ? 'Retry is available.' : null,
      onRetry: onRetry,
      icon: Icons.error_outline,
    );
  }
}

class AppRetryState extends StatelessWidget {
  const AppRetryState({
    required this.title,
    this.message,
    this.onRetry,
    this.icon = Icons.refresh,
    super.key,
  });

  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: message == null ? title : '$title. $message',
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: AppSpacing.sm),
              Text(title, textAlign: TextAlign.center),
              if (message != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(message!, textAlign: TextAlign.center),
              ],
              if (onRetry != null) ...[
                const SizedBox(height: AppSpacing.md),
                AppButton.secondary(label: 'Try again', onPressed: onRetry),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AppOfflineState extends StatelessWidget {
  const AppOfflineState({this.onRetry, super.key});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return AppRetryState(
      title: 'You are offline',
      message: 'Check your connection and try again.',
      onRetry: onRetry,
      icon: Icons.wifi_off_outlined,
    );
  }
}
