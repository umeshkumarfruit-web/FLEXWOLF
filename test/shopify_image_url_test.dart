import 'package:flexwolf/core/widgets/shopify_image_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('requests a smaller Shopify image while keeping its version', () {
    final result = shopifyImageUrlForWidth(
      'https://cdn.shopify.com/s/files/1/shop/files/top.jpg?v=123',
      480,
    );
    final uri = Uri.parse(result);
    expect(uri.queryParameters['v'], '123');
    expect(uri.queryParameters['width'], '480');
  });

  test('caps large Shopify images and leaves other hosts alone', () {
    expect(
      Uri.parse(
        shopifyImageUrlForWidth(
          'https://flexwolf.co/cdn/shop/files/banner.png?width=2000',
          2000,
        ),
      ).queryParameters['width'],
      '1440',
    );
    const other = 'https://images.example.com/signed.jpg?token=abc';
    expect(shopifyImageUrlForWidth(other, 480), other);
  });
}
