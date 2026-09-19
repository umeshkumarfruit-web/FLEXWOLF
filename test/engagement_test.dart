import 'package:flexwolf/core/storage/local_storage.dart';
import 'package:flexwolf/features/engagement/data/engagement_repository.dart';
import 'package:flexwolf/features/engagement/domain/engagement_models.dart';
import 'package:flexwolf/features/shop/domain/pagination.dart';
import 'package:flexwolf/features/shop/domain/product.dart';
import 'package:flexwolf/features/shop/domain/shop_repositories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('recently viewed removes duplicates and enforces max history', () async {
    final repo = LocalEngagementRepository(
      storage: InMemoryLocalStorage(),
      products: _Products(),
    );
    for (var i = 0; i < engagementHistoryLimit + 2; i++) {
      await repo.trackRecentlyViewed(_product('p$i'));
    }
    await repo.trackRecentlyViewed(_product('p5'));
    final items = await repo.loadRecentlyViewed();
    expect(items.length, engagementHistoryLimit);
    expect(items.first.handle, 'p5');
    expect(items.where((item) => item.handle == 'p5'), hasLength(1));
  });

  test('continue shopping resumes last product and collection', () async {
    final repo = LocalEngagementRepository(
      storage: InMemoryLocalStorage(),
      products: _Products(),
    );
    await repo.trackRecentlyViewed(
      _product('hoodie'),
      collectionHandle: 'new-drop',
    );
    final state = await repo.loadContinueShopping();
    expect(state.lastProductHandle, 'hoodie');
    expect(state.lastCollectionHandle, 'new-drop');
    expect(state.hasResumePoint, isTrue);
  });

  test(
    'recommendations use Shopify repository data without hardcoding',
    () async {
      final repo = LocalEngagementRepository(
        storage: InMemoryLocalStorage(),
        products: _Products(),
      );
      final products = await repo.recommendations(
        const ProductRecommendationRequest(
          kind: RecommendationKind.similarProducts,
          productHandle: 'p1',
          limit: 2,
        ),
      );
      expect(products.map((product) => product.handle), ['p2', 'p3']);
    },
  );

  test('engagement ignores malformed local cache entries', () async {
    final storage = InMemoryLocalStorage();
    await storage.writeString(
      'engagement.continue_shopping.guest',
      '{bad json',
    );
    await storage.writeString(
      'engagement.recently_viewed.guest',
      '[{"productId":"p1"},{"handle":"missing-product"}]',
    );
    await storage.writeString(
      'engagement.alerts',
      '[{"kind":"priceDrop","productId":"p1"}]',
    );
    final repo = LocalEngagementRepository(
      storage: storage,
      products: _Products(),
    );
    expect((await repo.loadContinueShopping()).hasResumePoint, isFalse);
    expect(await repo.loadRecentlyViewed(), isEmpty);
    await repo.registerAlert(
      EngagementAlertRegistration(
        kind: EngagementAlertKind.priceDrop,
        productId: 'p2',
        productHandle: 'p2',
        createdAt: DateTime.utc(2026),
      ),
    );
  });
  test('alert registrations are product specific and removable', () async {
    final repo = LocalEngagementRepository(
      storage: InMemoryLocalStorage(),
      products: _Products(),
    );
    final registration = EngagementAlertRegistration(
      kind: EngagementAlertKind.backInStock,
      productId: 'gid://shopify/Product/1',
      productHandle: 'p1',
      email: 'buyer@example.com',
      createdAt: DateTime.utc(2026),
    );
    final saved = await repo.registerAlert(registration);
    expect(saved.key, contains('backInStock'));
    await repo.removeAlert(registration);
  });
}

class _Products implements ProductRepository {
  @override
  Future<PaginatedResult<ProductSummary>> fetchProducts(
    PaginationRequest pagination,
  ) async => PaginatedResult(
    items: [_product('p1'), _product('p2'), _product('p3')],
    pageInfo: const PageInfo(hasNextPage: false),
  );

  @override
  Future<ProductSummary?> fetchProductByHandle(String handle) async =>
      _product(handle);

  @override
  Future<ProductSummary?> fetchProductById(String id) async => _product(id);

  @override
  Future<PaginatedResult<ProductSummary>> fetchProductsByCollection({
    required String collectionHandle,
    required PaginationRequest pagination,
  }) async => PaginatedResult(
    items: [_product('c1'), _product('c2')],
    pageInfo: const PageInfo(hasNextPage: false),
  );
}

ProductSummary _product(String handle) => ProductSummary(
  id: 'gid://shopify/Product/$handle',
  handle: handle,
  title: 'Product $handle',
  availableForSale: true,
);
