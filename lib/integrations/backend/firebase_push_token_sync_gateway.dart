import 'package:cloud_functions/cloud_functions.dart';
import 'package:flexwolf/features/notifications/domain/notification_models.dart';
import 'package:flexwolf/integrations/backend/backend_boundary.dart';

class FirebasePushTokenSyncGateway implements PushTokenSyncGateway {
  FirebasePushTokenSyncGateway()
    : _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFunctions _functions;

  @override
  Future<void> register(PushTokenRegistration registration) async {
    await _functions.httpsCallable('registerCustomerPush').call(
      <String, Object?>{'token': registration.token},
    );
  }

  @override
  Future<void> remove(PushTokenRegistration? registration) async {
    if (registration == null) return;
    await _functions.httpsCallable('removeCustomerPush').call(<String, Object?>{
      'token': registration.token,
    });
  }
}
