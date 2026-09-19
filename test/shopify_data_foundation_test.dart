import 'dart:convert';
import 'dart:io';

import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/features/shop/domain/collection.dart';
import 'package:flexwolf/features/shop/domain/money.dart';
import 'package:flexwolf/features/shop/domain/pagination.dart';
import 'package:flexwolf/features/shop/domain/product.dart';
import 'package:flexwolf/features/shop/domain/product_media.dart';
import 'package:flexwolf/features/shop/domain/product_variant.dart';
import 'package:flexwolf/features/shop/data/shopify_shop_repositories.dart';
import 'package:flexwolf/integrations/shopify/graphql/shopify_graphql_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Money preserves decimal precision without floating point conversion',
    () {
      final money = Money.fromShopify(<String, Object?>{
        'amount': '39.95',
        'currencyCode': 'USD',
      });

      expect(money.amount.toString(), '39.95');
      expect(money.currencyCode, 'USD');
      expect(() => DecimalAmount.parse('39.9.5'), throwsFormatException);
    },
  );

  test(
    'Product parser maps variants, media, options, metafields, and collections',
    () async {
      final product = ProductSummary.fromShopify(
        await _fixture('product_fixture.json'),
      );

      expect(product.id, 'gid://shopify/Product/1');
      expect(product.handle, 'flex-tee');
      expect(product.featuredImage?.altText, 'Flex Tee front');
      expect(
        product.media.map((media) => media.kind),
        contains(ProductMediaKind.video),
      );
      expect(product.variants.single.sku, 'FW-TEE-BLK-M');
      expect(product.variants.single.color, 'Black');
      expect(product.variants.single.size, 'M');
      expect(product.variants.single.price.amount.toString(), '39.95');
      expect(
        product.options.map((option) => option.name),
        containsAll(<String>['Color', 'Size']),
      );
      expect(product.metafields.single.key, 'fabric');
      expect(product.collectionIds, contains('gid://shopify/Collection/1'));
    },
  );

  test('Product parser tolerates missing optional Shopify fields', () {
    final product = ProductSummary.fromShopify(<String, Object?>{
      'id': 'gid://shopify/Product/2',
      'handle': 'minimal-product',
      'title': 'Minimal Product',
      'availableForSale': false,
    });

    expect(product.featuredImage, isNull);
    expect(product.variants, isEmpty);
    expect(product.tags, isEmpty);
  });

  test('Variant parser does not assume size or color options exist', () {
    final variant = ProductVariant.fromShopify(<String, Object?>{
      'id': 'gid://shopify/ProductVariant/2',
      'availableForSale': true,
      'price': <String, Object?>{'amount': '10.00', 'currencyCode': 'USD'},
      'selectedOptions': <Map<String, Object?>>[
        <String, Object?>{'name': 'Material', 'value': 'Cotton'},
      ],
    });

    expect(variant.color, isNull);
    expect(variant.size, isNull);
    expect(variant.selectedOptionValue('Material'), 'Cotton');
  });

  test('Collection parser supports paginated products', () async {
    final collection = ProductCollection.fromShopify(
      await _fixture('collection_fixture.json'),
    );

    expect(collection.handle, 'new-arrivals');
    expect(collection.products?.items.single.handle, 'flex-tee');
    expect(collection.products?.pageInfo.hasNextPage, isTrue);
    expect(collection.products?.pageInfo.endCursor, 'cursor-1');
  });

  test('PaginatedResult append prevents duplicate products', () {
    final first = PaginatedResult<ProductSummary>(
      items: <ProductSummary>[
        _product('gid://shopify/Product/1', 'first'),
        _product('gid://shopify/Product/2', 'second'),
      ],
      pageInfo: const PageInfo(hasNextPage: true, endCursor: 'cursor-1'),
    );
    final second = PaginatedResult<ProductSummary>(
      items: <ProductSummary>[
        _product('gid://shopify/Product/2', 'second-updated'),
        _product('gid://shopify/Product/3', 'third'),
      ],
      pageInfo: const PageInfo(hasNextPage: false),
    );

    final appended = first.append(second, (product) => product.id);

    expect(appended.items.map((product) => product.id), <String>[
      'gid://shopify/Product/1',
      'gid://shopify/Product/2',
      'gid://shopify/Product/3',
    ]);
    expect(appended.items[1].title, 'second-updated');
  });

  test('Repository maps malformed pagination to AppException', () async {
    final repository = ShopifyProductRepository(
      FakeShopifyGraphqlClient(
        const ShopifyGraphqlResponse(
          data: <String, Object?>{'products': <String, Object?>{}},
        ),
      ),
    );

    await expectLater(
      repository.fetchProducts(const PaginationRequest()),
      throwsA(isA<AppException>()),
    );
  });

  test('Repository parses product connection response', () async {
    final product = await _fixture('product_fixture.json');
    final repository = ShopifyProductRepository(
      FakeShopifyGraphqlClient(
        ShopifyGraphqlResponse(
          data: <String, Object?>{
            'products': <String, Object?>{
              'nodes': <Map<String, Object?>>[product],
              'pageInfo': <String, Object?>{
                'hasNextPage': false,
                'endCursor': null,
              },
            },
          },
        ),
      ),
    );

    final result = await repository.fetchProducts(
      const PaginationRequest(first: 1),
    );

    expect(result.items.single.handle, 'flex-tee');
    expect(result.pageInfo.hasNextPage, isFalse);
  });
}

Future<Map<String, Object?>> _fixture(String name) async {
  final file = File('lib/features/shop/data/fixtures/$name');
  return jsonDecode(await file.readAsString()) as Map<String, Object?>;
}

ProductSummary _product(String id, String title) {
  return ProductSummary(
    id: id,
    handle: title,
    title: title,
    availableForSale: true,
  );
}

class FakeShopifyGraphqlClient implements ShopifyGraphqlClient {
  const FakeShopifyGraphqlClient(this.response);

  final ShopifyGraphqlResponse response;

  @override
  Future<ShopifyGraphqlResponse> query(
    ShopifyGraphqlRequest request, {
    cancelToken,
  }) async {
    return response;
  }
}
