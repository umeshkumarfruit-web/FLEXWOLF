import 'package:flexwolf/core/services/service_registry.dart';
import 'package:flexwolf/features/engagement/data/engagement_repository.dart';
import 'package:flexwolf/features/engagement/domain/engagement_models.dart';
import 'package:flexwolf/features/shop/data/shop_providers.dart';
import 'package:flexwolf/features/shop/domain/product.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final engagementRepositoryProvider = Provider<EngagementRepository>((ref) {
  return LocalEngagementRepository(
    storage: ref.watch(localStorageProvider),
    products: ref.watch(productRepositoryProvider),
  );
});

final recentlyViewedProvider =
    FutureProvider.autoDispose<List<RecentlyViewedItem>>((ref) {
      return ref.watch(engagementRepositoryProvider).loadRecentlyViewed();
    });

final continueShoppingProvider =
    FutureProvider.autoDispose<ContinueShoppingState>((ref) {
      return ref.watch(engagementRepositoryProvider).loadContinueShopping();
    });

final recommendationsProvider = FutureProvider.autoDispose
    .family<List<ProductSummary>, ProductRecommendationRequest>((ref, request) {
      return ref.watch(engagementRepositoryProvider).recommendations(request);
    });
