import 'package:flexwolf/features/notifications/domain/notification_models.dart';

abstract interface class BackendGateway {}

abstract interface class PushTokenSyncGateway {
  Future<void> register(PushTokenRegistration registration);

  Future<void> remove(PushTokenRegistration? registration);
}

class NoopPushTokenSyncGateway implements PushTokenSyncGateway {
  const NoopPushTokenSyncGateway();

  @override
  Future<void> register(PushTokenRegistration registration) async {}

  @override
  Future<void> remove(PushTokenRegistration? registration) async {}
}
