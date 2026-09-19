import 'dart:async';

import 'package:flexwolf/features/notifications/domain/notification_models.dart';
import 'package:flexwolf/integrations/analytics/analytics_boundary.dart';
import 'package:flexwolf/integrations/firebase/firebase_boundary.dart';

class NotificationCoordinator {
  NotificationCoordinator({
    required NotificationRepository repository,
    required FirebaseMessagingGateway messaging,
    required AnalyticsGateway analytics,
    required void Function(String route) openRoute,
  }) : this._(repository, messaging, analytics, openRoute);

  NotificationCoordinator._(
    this._repository,
    this._messaging,
    this._analytics,
    this._openRoute,
  );

  final NotificationRepository _repository;
  final FirebaseMessagingGateway _messaging;
  final AnalyticsGateway _analytics;
  final void Function(String route) _openRoute;
  static const _maxSeenNotifications = 128;
  final Set<String> _seen = <String>{};
  final List<StreamSubscription<Object>> _subscriptions =
      <StreamSubscription<Object>>[];
  bool _started = false;

  Future<void> start({String? customerId}) async {
    if (_started) return;
    _started = true;
    await _repository.initialize();
    await _repository.restoreRegistration();
    await _repository.registerDevice(customerId: customerId);

    _subscriptions.add(
      _messaging.tokenRefreshes().listen(
        (token) => _repository.updateToken(token, customerId: customerId),
        onError: (_) {},
      ),
    );
    _subscriptions.add(
      _messaging.foregroundNotifications().listen(
        handleReceived,
        onError: (_) {},
      ),
    );
    _subscriptions.add(
      _messaging.notificationOpens().listen(handleOpened, onError: (_) {}),
    );

    final initial = await _messaging.initialNotification();
    if (initial != null) {
      await handleOpened(initial);
    }
  }

  Future<void> dispose() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    _started = false;
  }

  Future<void> handleReceived(NotificationPayload payload) async {
    if (!_markSeen(payload.id)) return;
    await _analytics.track(
      const AnalyticsEvent(name: AppAnalyticsEvents.notificationReceived),
    );
  }

  Future<void> handleOpened(NotificationPayload payload) async {
    if (!_markSeen('open:${payload.id}')) return;
    final action = _repository.actionFor(payload);
    if (!action.isValid || action.route == null) return;
    await _analytics.track(
      const AnalyticsEvent(name: AppAnalyticsEvents.notificationNavigation),
    );
    _openRoute(action.route!);
  }

  bool _markSeen(String id) {
    if (_seen.contains(id)) return false;
    if (_seen.length >= _maxSeenNotifications) {
      _seen.remove(_seen.first);
    }
    _seen.add(id);
    return true;
  }
}
