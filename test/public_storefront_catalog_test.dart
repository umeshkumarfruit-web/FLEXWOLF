import 'package:flexwolf/features/shop/data/public_storefront_catalog_repository.dart';
import 'package:flexwolf/features/shop/domain/pagination.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'public product detail accepts text tags and live availability',
    () async {
      final repository = PublicStorefrontCatalogRepository(
        bundle: _DetailBundle(),
      );
      final product = await repository.fetchProductByHandle(
        'wolfmark-wrap-oversized-tee',
      );
      expect(product?.title, 'Wolfmark Wrap Oversized Tee');
      expect(product?.tags, ['graphic tee', 'wolfmark tee']);
      expect(product?.availableForSale, isTrue);
      expect(product?.variants.single.availableForSale, isTrue);
    },
  );
  test('public catalog maps live product fields and advances pages', () async {
    final bundle = _CatalogBundle();
    final repository = PublicStorefrontCatalogRepository(bundle: bundle);
    final first = await repository.fetchProducts(
      const PaginationRequest(first: 1),
    );

    expect(first.items.single.title, 'Flex Arm Tank');
    expect(
      first.items.single.featuredImage?.url,
      'https://example.com/tank.jpg',
    );
    expect(first.items.single.variants.single.price.amount.value, '16.99');
    expect(first.items.single.variants.single.color, 'Black');
    expect(
      first.items.single.variants.single.image?.url,
      'https://example.com/tank-black.jpg',
    );
    expect(first.items.single.variants.single.size, 'S');
    expect(first.pageInfo.endCursor, '2');

    final second = await repository.fetchProducts(
      PaginationRequest(first: 1, after: first.pageInfo.endCursor),
    );
    expect(second.items, isEmpty);
    expect(second.pageInfo.hasNextPage, isFalse);
    expect(bundle.paths, [
      'collections/all-products/products.json?limit=1&page=1',
      'collections/all-products/products.json?limit=1&page=2',
    ]);
  });
}

class _CatalogBundle extends NetworkAssetBundle {
  _CatalogBundle() : super(Uri.parse('https://flexwolf.co/'));

  final paths = <String>[];

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    paths.add(key);
    if (key.contains('page=2')) return '{"products":[]}';
    return '''
    {
      "products": [{
        "id": 123,
        "handle": "flex-arm-tank",
        "title": "Flex Arm Tank",
        "image": {"src": "https://example.com/tank.jpg"},
        "images": [{"src":"https://example.com/tank-black.jpg","variant_ids":[456]}],
        "options": [
          {"name": "Color", "values": ["Black"]},
          {"name": "Size", "values": ["S"]}
        ],
        "variants": [{
          "id": 456,
          "title": "Black / S",
          "available": true,
          "price": "16.99",
          "compare_at_price": "22.00",
          "option1": "Black",
          "option2": "S"
        }]
      }]
    }
    ''';
  }
}

class _DetailBundle extends NetworkAssetBundle {
  _DetailBundle() : super(Uri.parse('https://flexwolf.co/'));

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    if (key.endsWith('.js')) {
      return '{"variants":[{"id":456,"available":true}]}';
    }
    return '''
    {"product":{
      "id":123,"handle":"wolfmark-wrap-oversized-tee",
      "title":"Wolfmark Wrap Oversized Tee",
      "tags":"graphic tee, wolfmark tee",
      "options":[{"name":"Size","values":["S"]}],
      "variants":[{"id":456,"title":"S","price":"30.00","option1":"S"}],
      "images":[]
    }}
    ''';
  }
}
