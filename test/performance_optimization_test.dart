import 'package:flexwolf/app/config/app_config.dart';
import 'package:flexwolf/app/config/app_environment.dart';
import 'package:flexwolf/core/storage/secure_storage.dart';
import 'package:flexwolf/core/widgets/app_remote_image.dart';
import 'package:flexwolf/features/notifications/data/firebase_notification_repository.dart';
import 'package:flexwolf/features/notifications/data/notification_coordinator.dart';
import 'package:flexwolf/features/notifications/domain/notification_models.dart';
import 'package:flexwolf/features/shop/data/shop_providers.dart';
import 'package:flexwolf/features/shop/domain/catalog_cache.dart';
import 'package:flexwolf/features/shop/domain/pagination.dart';
import 'package:flexwolf/features/shop/domain/product.dart';
import 'package:flexwolf/integrations/analytics/analytics_boundary.dart';
import 'package:flexwolf/integrations/backend/backend_boundary.dart';
import 'package:flexwolf/integrations/firebase/firebase_boundary.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shop catalog cache evicts stale pages and bounds entries', () {
    final cache = ShopCatalogCache(
      policy: const CatalogCachePolicy(
        maxEntries: 2,
        staleAfter: Duration(minutes: 15),
        environmentKey: 'test',
      ),
    );
    final fresh = CachedPage<ProductSummary>(
      result: PaginatedResult<ProductSummary>(
        items: [_product('1')],
        pageInfo: const PageInfo(hasNextPage: false),
      ),
      cachedAt: DateTime.now(),
    );
    final stale = CachedPage<ProductSummary>(
      result: PaginatedResult<ProductSummary>(
        items: [_product('old')],
        pageInfo: const PageInfo(hasNextPage: false),
      ),
      cachedAt: DateTime.now().subtract(const Duration(hours: 1)),
    );

    cache.write('old', stale);
    expect(cache.read('old'), isNull);

    cache.write('one', fresh);
    cache.write('two', fresh);
    cache.write('three', fresh);

    expect(cache.read('one'), isNull);
    expect(cache.read('two'), isNotNull);
    expect(cache.read('three'), isNotNull);
  });

  testWidgets('remote image uses bounded decode cache width', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: Size(390, 844), devicePixelRatio: 3),
          child: AppRemoteImage(imageUrl: 'https://cdn.flexwolf.test/item.jpg'),
        ),
      ),
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect(image.image.runtimeType.toString(), 'ResizeImage');
    expect(
      tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage))
          .useOldImageOnUrlChange,
      isTrue,
    );
  });

  test(
    'notification open de-duplication remains per notification id',
    () async {
      final analytics = _Analytics();
      final routes = <String>[];
      final repo = FirebaseNotificationRepository(
        messaging: const _Messaging(),
        storage: _SecureStorage(),
        tokenSync: const NoopPushTokenSyncGateway(),
      );
      final coordinator = NotificationCoordinator(
        repository: repo,
        messaging: const _Messaging(),
        analytics: analytics,
        openRoute: routes.add,
      );

      await coordinator.handleOpened(
        const NotificationPayload(
          id: 'one',
          title: 'One',
          deepLink: '/wishlist',
        ),
      );
      await coordinator.handleOpened(
        const NotificationPayload(
          id: 'one',
          title: 'One',
          deepLink: '/wishlist',
        ),
      );
      await coordinator.handleOpened(
        const NotificationPayload(
          id: 'two',
          title: 'Two',
          deepLink: '/account',
        ),
      );

      expect(routes, const ['/wishlist', '/account']);
      expect(analytics.events, const [
        AppAnalyticsEvents.notificationNavigation,
        AppAnalyticsEvents.notificationNavigation,
      ]);
    },
  );

  test('production config keeps verbose logging disabled', () {
    final config = AppConfig.forEnvironment(AppEnvironment.production);

    expect(config.allowsVerboseLogging, isFalse);
    expect(config.featureFlags.enableDiagnostics, isFalse);
  });
}

ProductSummary _product(String id) => ProductSummary(
  id: 'gid://shopify/Product/$id',
  handle: 'product-$id',
  title: 'Product $id',
  availableForSale: true,
);

class _Analytics implements AnalyticsGateway {
  final events = <String>[];

  @override
  Future<void> track(AnalyticsEvent event) async => events.add(event.name);
}

class _Messaging implements FirebaseMessagingGateway {
  const _Messaging();

  @override
  Future<String?> currentToken() async => null;

  @override
  Future<void> deleteToken() async {}

  @override
  Stream<NotificationPayload> foregroundNotifications() => const Stream.empty();

  @override
  Future<NotificationPayload?> initialNotification() async => null;

  @override
  Stream<NotificationPayload> notificationOpens() => const Stream.empty();

  @override
  Future<NotificationPermissionStatus> permissionStatus() async =>
      NotificationPermissionStatus.granted;

  @override
  Future<void> prepareMessaging() async {}

  @override
  Future<NotificationPermissionStatus> requestPermission() async =>
      NotificationPermissionStatus.granted;

  @override
  Stream<String> tokenRefreshes() => const Stream.empty();
}

class _SecureStorage implements SecureStorage {
  final _values = <String, String>{};

  @override
  Future<void> delete(String key) async => _values.remove(key);

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}
