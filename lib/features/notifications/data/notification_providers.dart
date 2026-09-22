import 'package:flexwolf/app/router/app_router.dart';
import 'package:flexwolf/core/services/service_registry.dart';
import 'package:flexwolf/features/notifications/data/firebase_notification_repository.dart';
import 'package:flexwolf/features/notifications/data/notification_coordinator.dart';
import 'package:flexwolf/features/notifications/domain/notification_models.dart';
import 'package:flexwolf/integrations/backend/backend_boundary.dart';
import 'package:flexwolf/integrations/backend/firebase_push_token_sync_gateway.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flexwolf/integrations/firebase/firebase_boundary.dart';
import 'package:flexwolf/integrations/firebase/firebase_messaging_gateway.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseMessagingGatewayProvider = Provider<FirebaseMessagingGateway>(
  (ref) => FlutterFireMessagingGateway(),
);

final pushTokenSyncGatewayProvider = Provider<PushTokenSyncGateway>(
  (ref) => Firebase.apps.isNotEmpty
      ? FirebasePushTokenSyncGateway()
      : const NoopPushTokenSyncGateway(),
);

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return FirebaseNotificationRepository(
    messaging: ref.watch(firebaseMessagingGatewayProvider),
    storage: ref.watch(secureStorageProvider),
    tokenSync: ref.watch(pushTokenSyncGatewayProvider),
  );
});

final notificationCoordinatorProvider = Provider<NotificationCoordinator>((
  ref,
) {
  final router = ref.watch(appRouterProvider);
  final coordinator = NotificationCoordinator(
    repository: ref.watch(notificationRepositoryProvider),
    messaging: ref.watch(firebaseMessagingGatewayProvider),
    analytics: ref.watch(analyticsGatewayProvider),
    openRoute: router.go,
  );
  ref.onDispose(coordinator.dispose);
  return coordinator;
});

final notificationLifecycleProvider = FutureProvider<void>((ref) async {
  await ref.watch(notificationCoordinatorProvider).start();
});

final notificationPermissionProvider =
    FutureProvider<NotificationPermissionStatus>((ref) {
      return ref.watch(notificationRepositoryProvider).permissionStatus();
    });
