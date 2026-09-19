import 'package:flexwolf/app/router/deep_link_contract.dart';
import 'package:flexwolf/app/router/route_names.dart';
import 'package:flexwolf/features/notifications/domain/notification_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = DeepLinkParser();

  test(
    'UAT classifies implemented deep links without overstating provider work',
    () {
      expect(
        parser.parse('/products/flex-tee').route,
        '/shop/products/flex-tee',
      );
      expect(
        parser.parse('/collections/training').route,
        '/shop/collections/training',
      );
      expect(parser.parse('/account/profile').route, AppRoutes.account);
      expect(parser.parse('/account/orders/1001').route, AppRoutes.account);
      expect(parser.parse('/wishlist').route, AppRoutes.wishlist);
      expect(parser.parse('/cart').route, AppDeepLinks.cart);
      expect(parser.parse('/checkout').route, AppDeepLinks.checkout);
    },
  );

  test('UAT verifies notification opens use the same safe route contract', () {
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
          id: 'admin',
          title: 'Admin',
          deepLink: '/admin',
        ),
      ).isValid,
      isFalse,
    );
  });
}
