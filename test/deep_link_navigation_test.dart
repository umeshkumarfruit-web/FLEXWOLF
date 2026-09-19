import 'package:flexwolf/app/router/deep_link_contract.dart';
import 'package:flexwolf/app/router/route_names.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = DeepLinkParser();

  test('deep link parser resolves supported destinations', () {
    expect(parser.parse('/').route, AppRoutes.home);
    expect(parser.parse('/wishlist').route, AppRoutes.wishlist);
    expect(parser.parse('/cart').route, AppDeepLinks.cart);
    expect(parser.parse('/checkout').route, AppDeepLinks.checkout);
    expect(parser.parse('/account/profile').route, AppRoutes.account);
    expect(parser.parse('/account/orders/1001').route, AppRoutes.account);
    expect(
      parser.parse('/products/flex-hoodie').route,
      '/shop/products/flex-hoodie',
    );
    expect(
      parser.parse('/collections/new-drop').route,
      '/shop/collections/new-drop',
    );
    expect(
      parser.parse('/shop/products/flex-hoodie').route,
      '/shop/products/flex-hoodie',
    );
    expect(parser.parse('/offers/summer').route, '/shop/promotions/summer');
  });

  test('deep link parser falls back for unsafe or unavailable links', () {
    expect(
      parser.parse('/products/../admin').route,
      startsWith('/link-unavailable'),
    );
    expect(parser.parse('ftp://flexwolf.test/products/a').isValid, isFalse);
    expect(parser.parse('/unknown').isValid, isFalse);
  });
}
