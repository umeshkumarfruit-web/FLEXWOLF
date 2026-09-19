import 'package:flexwolf/core/services/service_registry.dart';
import 'package:flexwolf/features/shop/data/shop_providers.dart';
import 'package:flexwolf/features/wishlist/data/wishlist_repository.dart';
import 'package:flexwolf/features/wishlist/domain/wishlist.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  return LocalWishlistRepository(
    storage: ref.watch(localStorageProvider),
    products: ref.watch(productRepositoryProvider),
  );
});

final wishlistProvider = FutureProvider<WishlistState>((ref) {
  return ref.watch(wishlistRepositoryProvider).load();
});
