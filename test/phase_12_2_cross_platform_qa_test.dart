import 'package:flexwolf/app/router/deep_link_contract.dart';
import 'package:flexwolf/app/router/route_names.dart';
import 'package:flexwolf/features/home/app_section.dart';
import 'package:flexwolf/features/notifications/domain/notification_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = DeepLinkParser();

  test('Phase 12.2 QA verifies cross-platform top-level routes', () {
    expect(
      AppSection.values.map((section) => section.path).toSet(),
      containsAll(<String>[
        AppRoutes.home,
        AppRoutes.shop,
        AppRoutes.search,
        AppRoutes.wishlist,
        AppRoutes.support,
        AppRoutes.account,
      ]),
    );
  });

  test(
    'Phase 12.2 QA verifies commerce routes used by Android and iOS navigation',
    () {
      expect(
        parser.parse('/products/flex-tee').route,
        '/shop/products/flex-tee',
      );
      expect(
        parser.parse('/collections/training').route,
        '/shop/collections/training',
      );
      expect(parser.parse('/account/orders/1001').route, AppRoutes.account);
      expect('${AppRoutes.shop}/products/flex-tee', '/shop/products/flex-tee');
    },
  );

  test('Phase 12.2 QA verifies notification links route safely', () {
    expect(
      notificationActionFor(
        const NotificationPayload(
          id: 'wishlist',
          title: 'Wishlist',
          deepLink: '/wishlist',
        ),
      ).route,
      AppRoutes.wishlist,
    );
    expect(
      notificationActionFor(
        const NotificationPayload(id: 'bad', title: 'Bad', deepLink: '/admin'),
      ).isValid,
      isFalse,
    );
  });
}
