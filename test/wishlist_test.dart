import 'package:flexwolf/core/storage/local_storage.dart';
import 'package:flexwolf/features/shop/domain/pagination.dart';
import 'package:flexwolf/features/shop/domain/product.dart';
import 'package:flexwolf/features/shop/domain/shop_repositories.dart';
import 'package:flexwolf/features/wishlist/data/wishlist_repository.dart';
import 'package:flexwolf/features/wishlist/domain/wishlist.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('wishlist prevents duplicate guest items', () async {
    final repo = LocalWishlistRepository(
      storage: InMemoryLocalStorage(),
      products: _Products(),
    );
    final item = WishlistItem(productId: 'p1', handle: 'flex-tee');
    await repo.add(item);
    final state = await repo.add(item);
    expect(state.count, 1);
  });

  test('wishlist ignores malformed local cache entries', () async {
    final storage = InMemoryLocalStorage();
    await storage.writeString(
      'wishlist.guest',
      '[{"productId":"p1"},{"handle":"missing-product"},"bad"]',
    );
    final repo = LocalWishlistRepository(
      storage: storage,
      products: _Products(),
    );
    final state = await repo.load();
    expect(state.items, isEmpty);
  });
  test('wishlist merges guest items into customer state', () async {
    final repo = LocalWishlistRepository(
      storage: InMemoryLocalStorage(),
      products: _Products(),
    );
    await repo.add(WishlistItem(productId: 'p1', handle: 'flex-tee'));
    final state = await repo.mergeGuestIntoCustomer('customer-1');
    expect(state.isSynced, isTrue);
    expect(state.count, 1);
    expect((await repo.load()).count, 0);
  });
}

class _Products implements ProductRepository {
  @override
  Future<ProductSummary?> fetchProductByHandle(String handle) async =>
      ProductSummary(
        id: 'p1',
        handle: handle,
        title: 'Flex Tee',
        availableForSale: true,
      );
  @override
  Future<ProductSummary?> fetchProductById(String id) async => null;
  @override
  Future<PaginatedResult<ProductSummary>> fetchProducts(
    PaginationRequest pagination,
  ) async => throw UnimplementedError();
  @override
  Future<PaginatedResult<ProductSummary>> fetchProductsByCollection({
    required String collectionHandle,
    required PaginationRequest pagination,
  }) async => throw UnimplementedError();
}
