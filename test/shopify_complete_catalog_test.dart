import 'package:flexwolf/features/shop/data/shop_providers.dart';
import 'package:flexwolf/features/shop/domain/collection.dart';
import 'package:flexwolf/features/shop/domain/catalog_cache.dart';
import 'package:flexwolf/features/shop/domain/pagination.dart';
import 'package:flexwolf/features/shop/domain/product.dart';
import 'package:flexwolf/features/shop/domain/shop_repositories.dart';
import 'package:flexwolf/features/shop/presentation/shop_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shop loads one page at a time and stops at the last page', () async {
    final products = _PagedProductRepository();
    final controller = ShopController(
      repository: products,
      collectionRepository: _EmptyCollectionRepository(),
      cache: ShopCatalogCache(
        policy: const CatalogCachePolicy(
          maxEntries: 4,
          staleAfter: Duration(minutes: 5),
          environmentKey: 'test',
        ),
      ),
      initialCollection: const ShopCollectionTab(
        id: 'all',
        label: 'All Products',
      ),
    );

    await controller.loadInitial();

    expect(controller.current?.products.map((product) => product.id), [
      'product-1',
      'product-2',
    ]);
    expect(controller.current?.pageInfo.hasNextPage, isTrue);
    await controller.loadMore();
    expect(controller.current?.products.map((product) => product.id), [
      'product-1',
      'product-2',
      'product-3',
    ]);
    expect(controller.current?.pageInfo.hasNextPage, isFalse);
    await controller.loadMore();
    expect(products.requests.map((request) => request.first), [24, 24]);
    expect(products.requests.map((request) => request.after), [null, 'page-1']);
    controller.dispose();
  });
  test('shop stops when the next page repeats existing products', () async {
    final products = _RepeatingProductRepository();
    final controller = ShopController(
      repository: products,
      collectionRepository: _EmptyCollectionRepository(),
      cache: ShopCatalogCache(
        policy: const CatalogCachePolicy(
          maxEntries: 4,
          staleAfter: Duration(minutes: 5),
          environmentKey: 'repeat-test',
        ),
      ),
      initialCollection: const ShopCollectionTab(
        id: 'all',
        label: 'All Products',
      ),
    );

    await controller.loadInitial();
    await controller.loadMore();
    await controller.loadMore();

    expect(controller.current?.products.map((product) => product.id), [
      'product-1',
    ]);
    expect(controller.current?.pageInfo.hasNextPage, isFalse);
    expect(products.requests.length, 2);
    controller.dispose();
  });
}

class _PagedProductRepository implements ProductRepository {
  final requests = <PaginationRequest>[];

  @override
  Future<PaginatedResult<ProductSummary>> fetchProducts(
    PaginationRequest pagination,
  ) async {
    requests.add(pagination);
    if (pagination.after == null) {
      return PaginatedResult(
        items: [_product('product-1'), _product('product-2')],
        pageInfo: const PageInfo(hasNextPage: true, endCursor: 'page-1'),
      );
    }
    return PaginatedResult(
      items: [_product('product-3')],
      pageInfo: const PageInfo(hasNextPage: false),
    );
  }

  @override
  Future<ProductSummary?> fetchProductByHandle(String handle) async => null;

  @override
  Future<ProductSummary?> fetchProductById(String id) async => null;

  @override
  Future<PaginatedResult<ProductSummary>> fetchProductsByCollection({
    required String collectionHandle,
    required PaginationRequest pagination,
  }) => fetchProducts(pagination);
}

class _RepeatingProductRepository extends _PagedProductRepository {
  @override
  Future<PaginatedResult<ProductSummary>> fetchProducts(
    PaginationRequest pagination,
  ) async {
    requests.add(pagination);
    return PaginatedResult(
      items: [_product('product-1')],
      pageInfo: PageInfo(
        hasNextPage: true,
        endCursor: pagination.after == null ? 'page-1' : 'page-2',
      ),
    );
  }
}

class _EmptyCollectionRepository implements CollectionRepository {
  @override
  Future<PaginatedResult<ProductCollection>> fetchCollections(
    PaginationRequest pagination,
  ) async =>
      const PaginatedResult(items: [], pageInfo: PageInfo(hasNextPage: false));

  @override
  Future<ProductCollection?> fetchCollectionByHandle({
    required String handle,
    PaginationRequest? productsPagination,
  }) async => null;
}

ProductSummary _product(String id) =>
    ProductSummary(id: id, handle: id, title: id, availableForSale: true);
