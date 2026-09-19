import 'package:flexwolf/app/router/deep_link_contract.dart';
import 'package:flexwolf/app/router/route_names.dart';
import 'package:flexwolf/features/home/app_section.dart';
import 'package:flexwolf/features/notifications/domain/notification_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = DeepLinkParser();

  test('Phase 12.1 QA verifies top-level navigation routes are declared', () {
    final routes = AppSection.values.map((section) => section.path).toSet();

    expect(
      routes,
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

  test('Phase 12.1 QA verifies commerce and account deep links fail safe or route correctly', () {
    expect(parser.parse('/products/flex-tee').route, '/shop/products/flex-tee');
    expect(
      parser.parse('/collections/training').route,
      '/shop/collections/training',
    );
    expect(parser.parse('/account/orders/1001').route, AppRoutes.account);
    expect(parser.parse('/wishlist').route, AppRoutes.wishlist);
    expect(parser.parse('/cart').route, AppDeepLinks.cart);
    expect(parser.parse('/checkout').route, AppDeepLinks.checkout);
  });

  test(
    'Phase 12.1 QA verifies notification navigation reuses deep link safety',
    () {
      expect(
        notificationActionFor(
          const NotificationPayload(
            id: 'product',
            title: 'Product',
            deepLink: '/products/flex-tee',
          ),
        ).route,
        '/shop/products/flex-tee',
      );
      expect(
        notificationActionFor(
          const NotificationPayload(
            id: 'bad',
            title: 'Bad',
            deepLink: '/admin',
          ),
        ).isValid,
        isFalse,
      );
    },
  );
}
