import 'dart:convert';

import 'package:flexwolf/core/storage/local_storage.dart';
import 'package:flexwolf/features/engagement/domain/engagement_models.dart';
import 'package:flexwolf/features/shop/domain/pagination.dart';
import 'package:flexwolf/features/shop/domain/product.dart';
import 'package:flexwolf/features/shop/domain/shop_repositories.dart';

class LocalEngagementRepository implements EngagementRepository {
  LocalEngagementRepository({required this._storage, required this._products});

  static const _guestRecentKey = 'engagement.recently_viewed.guest';
  static const _guestContinueKey = 'engagement.continue_shopping.guest';
  static const _alertsKey = 'engagement.alerts';

  final LocalStorage _storage;
  final ProductRepository _products;

  @override
  Future<List<RecentlyViewedItem>> loadRecentlyViewed({
    String? customerId,
  }) async {
    final items = await _readRecent(_recentKey(customerId));
    final resolved = await Future.wait(
      items.map((item) async {
        final product =
            item.product ?? await _products.fetchProductByHandle(item.handle);
        return item.copyWith(product: product);
      }),
    );
    return resolved;
  }

  @override
  Future<List<RecentlyViewedItem>> trackRecentlyViewed(
    ProductSummary product, {
    String? customerId,
    String? collectionHandle,
  }) async {
    final key = _recentKey(customerId);
    final items = await _readRecent(key);
    items.removeWhere(
      (item) => item.productId == product.id || item.handle == product.handle,
    );
    items.insert(
      0,
      RecentlyViewedItem(
        productId: product.id,
        handle: product.handle,
        title: product.title,
        viewedAt: DateTime.now().toUtc(),
        collectionHandle: collectionHandle,
        product: product,
      ),
    );
    final limited = items.take(engagementHistoryLimit).toList(growable: false);
    await _writeRecent(key, limited);
    await updateContinueShopping(
      customerId: customerId,
      productHandle: product.handle,
      collectionHandle: collectionHandle,
    );
    return limited;
  }

  @override
  Future<ContinueShoppingState> loadContinueShopping({
    String? customerId,
  }) async {
    final raw = await _storage.readString(_continueKey(customerId));
    if (raw == null) return const ContinueShoppingState();
    final json = _decodeJson(raw);
    if (json is! Map<String, Object?>) return const ContinueShoppingState();
    return ContinueShoppingState(
      lastProductHandle: json['lastProductHandle'] as String?,
      lastCollectionHandle: json['lastCollectionHandle'] as String?,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }

  @override
  Future<ContinueShoppingState> updateContinueShopping({
    String? customerId,
    String? productHandle,
    String? collectionHandle,
  }) async {
    final previous = await loadContinueShopping(customerId: customerId);
    final next = ContinueShoppingState(
      lastProductHandle: productHandle ?? previous.lastProductHandle,
      lastCollectionHandle: collectionHandle ?? previous.lastCollectionHandle,
      updatedAt: DateTime.now().toUtc(),
    );
    await _storage.writeString(
      _continueKey(customerId),
      jsonEncode({
        if (next.lastProductHandle != null)
          'lastProductHandle': next.lastProductHandle,
        if (next.lastCollectionHandle != null)
          'lastCollectionHandle': next.lastCollectionHandle,
        'updatedAt': next.updatedAt!.toIso8601String(),
      }),
    );
    return next;
  }

  @override
  Future<List<ProductSummary>> recommendations(
    ProductRecommendationRequest request,
  ) async {
    final limit = request.limit.clamp(1, 20);
    if (request.collectionHandle != null) {
      final page = await _products.fetchProductsByCollection(
        collectionHandle: request.collectionHandle!,
        pagination: PaginationRequest(first: limit),
      );
      return _unique(
        page.items,
        excludeHandle: request.productHandle,
      ).take(limit).toList();
    }
    final page = await _products.fetchProducts(PaginationRequest(first: limit));
    return _unique(
      page.items,
      excludeHandle: request.productHandle,
    ).take(limit).toList();
  }

  @override
  Future<EngagementAlertRegistration> registerAlert(
    EngagementAlertRegistration registration,
  ) async {
    final alerts = await _readAlerts();
    alerts.removeWhere((item) => item.key == registration.key);
    alerts.add(registration);
    await _writeAlerts(alerts);
    return registration;
  }

  @override
  Future<void> removeAlert(EngagementAlertRegistration registration) async {
    final alerts = await _readAlerts();
    alerts.removeWhere((item) => item.key == registration.key);
    await _writeAlerts(alerts);
  }

  Future<List<RecentlyViewedItem>> _readRecent(String key) async {
    final raw = await _storage.readString(key);
    if (raw == null) return <RecentlyViewedItem>[];
    final json = _decodeJson(raw);
    if (json is! List) return <RecentlyViewedItem>[];
    return json
        .whereType<Map<String, Object?>>()
        .map(_recentFromJson)
        .nonNulls
        .toList();
  }

  Future<void> _writeRecent(String key, List<RecentlyViewedItem> items) =>
      _storage.writeString(key, jsonEncode(items.map(_recentToJson).toList()));

  Future<List<EngagementAlertRegistration>> _readAlerts() async {
    final raw = await _storage.readString(_alertsKey);
    if (raw == null) return <EngagementAlertRegistration>[];
    final json = _decodeJson(raw);
    if (json is! List) return <EngagementAlertRegistration>[];
    return json
        .whereType<Map<String, Object?>>()
        .map(_alertFromJson)
        .nonNulls
        .toList();
  }

  Future<void> _writeAlerts(List<EngagementAlertRegistration> alerts) =>
      _storage.writeString(
        _alertsKey,
        jsonEncode(alerts.map(_alertToJson).toList()),
      );

  String _recentKey(String? customerId) => customerId == null
      ? _guestRecentKey
      : 'engagement.recently_viewed.customer.$customerId';
  String _continueKey(String? customerId) => customerId == null
      ? _guestContinueKey
      : 'engagement.continue_shopping.customer.$customerId';
}

Object? _decodeJson(String raw) {
  try {
    return jsonDecode(raw);
  } on FormatException {
    return null;
  }
}

Iterable<ProductSummary> _unique(
  List<ProductSummary> products, {
  String? excludeHandle,
}) sync* {
  final seen = <String>{};
  for (final product in products) {
    if (product.handle == excludeHandle) continue;
    if (seen.add(product.id)) yield product;
  }
}

RecentlyViewedItem? _recentFromJson(Map<String, Object?> json) {
  final productId = json['productId'];
  final handle = json['handle'];
  if (productId is! String ||
      productId.trim().isEmpty ||
      handle is! String ||
      handle.trim().isEmpty) {
    return null;
  }
  return RecentlyViewedItem(
    productId: productId,
    handle: handle,
    title: json['title'] as String? ?? handle,
    viewedAt:
        DateTime.tryParse(json['viewedAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    collectionHandle: json['collectionHandle'] as String?,
  );
}

Map<String, Object?> _recentToJson(RecentlyViewedItem item) => {
  'productId': item.productId,
  'handle': item.handle,
  'title': item.title,
  'viewedAt': item.viewedAt.toIso8601String(),
  if (item.collectionHandle != null) 'collectionHandle': item.collectionHandle,
};

EngagementAlertRegistration? _alertFromJson(Map<String, Object?> json) {
  final productId = json['productId'];
  final productHandle = json['productHandle'];
  if (productId is! String ||
      productId.trim().isEmpty ||
      productHandle is! String ||
      productHandle.trim().isEmpty) {
    return null;
  }
  return EngagementAlertRegistration(
    kind: EngagementAlertKind.values.firstWhere(
      (kind) => kind.name == json['kind'],
      orElse: () => EngagementAlertKind.backInStock,
    ),
    productId: productId,
    productHandle: productHandle,
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    customerId: json['customerId'] as String?,
    email: json['email'] as String?,
  );
}

Map<String, Object?> _alertToJson(EngagementAlertRegistration item) => {
  'kind': item.kind.name,
  'productId': item.productId,
  'productHandle': item.productHandle,
  'createdAt': item.createdAt.toIso8601String(),
  if (item.customerId != null) 'customerId': item.customerId,
  if (item.email != null) 'email': item.email,
};
