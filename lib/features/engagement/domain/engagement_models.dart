import 'package:flexwolf/features/shop/domain/product.dart';

const engagementHistoryLimit = 20;

enum RecommendationKind {
  recommendedProducts,
  youMayAlsoLike,
  similarProducts,
  trendingProducts,
}

enum EngagementAlertKind { backInStock, priceDrop }

class RecentlyViewedItem {
  const RecentlyViewedItem({
    required this.productId,
    required this.handle,
    required this.title,
    required this.viewedAt,
    this.collectionHandle,
    this.product,
  });

  final String productId;
  final String handle;
  final String title;
  final DateTime viewedAt;
  final String? collectionHandle;
  final ProductSummary? product;

  RecentlyViewedItem copyWith({ProductSummary? product}) => RecentlyViewedItem(
    productId: productId,
    handle: handle,
    title: title,
    viewedAt: viewedAt,
    collectionHandle: collectionHandle,
    product: product ?? this.product,
  );
}

class ContinueShoppingState {
  const ContinueShoppingState({
    this.lastProductHandle,
    this.lastCollectionHandle,
    this.updatedAt,
  });

  final String? lastProductHandle;
  final String? lastCollectionHandle;
  final DateTime? updatedAt;

  bool get hasResumePoint =>
      lastProductHandle != null || lastCollectionHandle != null;
}

class ProductRecommendationRequest {
  const ProductRecommendationRequest({
    required this.kind,
    this.productHandle,
    this.collectionHandle,
    this.limit = 10,
  });

  final RecommendationKind kind;
  final String? productHandle;
  final String? collectionHandle;
  final int limit;
}

class EngagementAlertRegistration {
  const EngagementAlertRegistration({
    required this.kind,
    required this.productId,
    required this.productHandle,
    required this.createdAt,
    this.customerId,
    this.email,
  });

  final EngagementAlertKind kind;
  final String productId;
  final String productHandle;
  final DateTime createdAt;
  final String? customerId;
  final String? email;

  String get key => '${kind.name}:$productId:${customerId ?? email ?? 'guest'}';
}

abstract interface class EngagementRepository {
  Future<List<RecentlyViewedItem>> loadRecentlyViewed({String? customerId});

  Future<List<RecentlyViewedItem>> trackRecentlyViewed(
    ProductSummary product, {
    String? customerId,
    String? collectionHandle,
  });

  Future<ContinueShoppingState> loadContinueShopping({String? customerId});

  Future<ContinueShoppingState> updateContinueShopping({
    String? customerId,
    String? productHandle,
    String? collectionHandle,
  });

  Future<List<ProductSummary>> recommendations(
    ProductRecommendationRequest request,
  );

  Future<EngagementAlertRegistration> registerAlert(
    EngagementAlertRegistration registration,
  );

  Future<void> removeAlert(EngagementAlertRegistration registration);
}
