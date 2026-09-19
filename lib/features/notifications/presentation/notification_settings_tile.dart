import 'package:flexwolf/core/services/service_registry.dart';
import 'package:flexwolf/core/widgets/app_button.dart';
import 'package:flexwolf/features/notifications/data/notification_providers.dart';
import 'package:flexwolf/features/notifications/domain/notification_models.dart';
import 'package:flexwolf/integrations/analytics/analytics_boundary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationSettingsTile extends ConsumerWidget {
  const NotificationSettingsTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permission = ref.watch(notificationPermissionProvider);
    return Semantics(
      label: 'Notification permission settings',
      child: permission.when(
        loading: () => const ListTile(
          title: Text('Notifications'),
          subtitle: Text('Checking permission'),
        ),
        error: (error, stack) => ListTile(
          title: const Text('Notifications'),
          subtitle: Text(error.toString()),
          trailing: AppButton.text(
            label: 'Retry',
            onPressed: () => ref.invalidate(notificationPermissionProvider),
          ),
        ),
        data: (status) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.notifications_outlined),
          title: const Text('Notifications'),
          subtitle: Text(_label(status)),
          trailing: status == NotificationPermissionStatus.granted
              ? null
              : AppButton.text(
                  label: 'Enable',
                  semanticLabel: 'Request notification permission',
                  onPressed: () async {
                    final next = await ref
                        .read(notificationRepositoryProvider)
                        .requestPermission();
                    await ref
                        .read(analyticsGatewayProvider)
                        .track(
                          AnalyticsEvent(
                            name: AppAnalyticsEvents.notificationPermission,
                            parameters: {'status': next.name},
                          ),
                        );
                    ref.invalidate(notificationPermissionProvider);
                  },
                ),
        ),
      ),
    );
  }
}

String _label(NotificationPermissionStatus status) {
  return switch (status) {
    NotificationPermissionStatus.granted => 'Enabled',
    NotificationPermissionStatus.denied => 'Denied',
    NotificationPermissionStatus.provisional => 'Provisional',
    NotificationPermissionStatus.unknown => 'Not configured',
  };
}
