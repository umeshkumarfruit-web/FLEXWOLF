import 'dart:convert';

import 'package:flexwolf/core/storage/local_storage.dart';
import 'package:flexwolf/features/shop/domain/product.dart';
import 'package:flexwolf/features/shop/domain/shop_repositories.dart';
import 'package:flexwolf/features/wishlist/domain/wishlist.dart';

class LocalWishlistRepository implements WishlistRepository {
  LocalWishlistRepository({
    required LocalStorage storage,
    required ProductRepository products,
  }) : this._(storage, products);

  LocalWishlistRepository._(this._storage, this._products);

  static const _guestKey = 'wishlist.guest';
  final LocalStorage _storage;
  final ProductRepository _products;
  final Map<String, Future<ProductSummary?>> _productRequests = {};

  @override
  Future<WishlistState> load({String? customerId}) async =>
      _state(await _read(_key(customerId)), customerId: customerId);

  @override
  Future<WishlistState> add(WishlistItem item, {String? customerId}) async {
    final items = await _read(_key(customerId));
    if (!items.any((existing) => existing.key == item.key)) {
      items.add(item);
    }
    await _write(_key(customerId), items);
    return _state(items, customerId: customerId);
  }

  @override
  Future<WishlistState> remove(
    String productId, {
    String? variantId,
    String? customerId,
  }) async {
    final items = await _read(_key(customerId));
    items.removeWhere(
      (item) => item.productId == productId && item.variantId == variantId,
    );
    await _write(_key(customerId), items);
    return _state(items, customerId: customerId);
  }

  @override
  Future<WishlistState> toggle(WishlistItem item, {String? customerId}) async {
    final loaded = await load(customerId: customerId);
    return loaded.containsProduct(item.productId, variantId: item.variantId)
        ? remove(
            item.productId,
            variantId: item.variantId,
            customerId: customerId,
          )
        : add(item, customerId: customerId);
  }

  @override
  Future<WishlistState> mergeGuestIntoCustomer(String customerId) async {
    final guest = await _read(_guestKey);
    final customer = await _read(_key(customerId));
    for (final item in guest) {
      if (!customer.any((existing) => existing.key == item.key)) {
        customer.add(item);
      }
    }
    await _write(_key(customerId), customer);
    await _storage.remove(_guestKey);
    return _state(customer, customerId: customerId);
  }

  Future<WishlistState> _state(
    List<WishlistItem> items, {
    String? customerId,
  }) async {
    final resolved = await Future.wait(
      items.map((item) async {
        final product = item.product ?? await _resolve(item);
        return item.copyWith(product: product);
      }),
    );
    return WishlistState(items: resolved, isSynced: customerId != null);
  }

  Future<ProductSummary?> _resolve(WishlistItem item) {
    return _productRequests[item.handle] ??= _products
        .fetchProductByHandle(item.handle)
        .whenComplete(() {
          _productRequests.remove(item.handle);
        });
  }

  Future<List<WishlistItem>> _read(String key) async {
    final raw = await _storage.readString(key);
    if (raw == null) return <WishlistItem>[];
    final decoded = _decodeJson(raw);
    if (decoded is! List) return <WishlistItem>[];
    return decoded
        .whereType<Map<String, Object?>>()
        .map(_fromJson)
        .nonNulls
        .toList();
  }

  Future<void> _write(String key, List<WishlistItem> items) =>
      _storage.writeString(key, jsonEncode(items.map(_toJson).toList()));
  String _key(String? customerId) =>
      customerId == null ? _guestKey : 'wishlist.customer.$customerId';
}

Object? _decodeJson(String raw) {
  try {
    return jsonDecode(raw);
  } on FormatException {
    return null;
  }
}

WishlistItem? _fromJson(Map<String, Object?> json) {
  final productId = json['productId'];
  final handle = json['handle'];
  if (productId is! String ||
      productId.trim().isEmpty ||
      handle is! String ||
      handle.trim().isEmpty) {
    return null;
  }
  return WishlistItem(
    productId: productId,
    handle: handle,
    variantId: json['variantId'] as String?,
    addedAt: DateTime.tryParse(json['addedAt'] as String? ?? ''),
  );
}

Map<String, Object?> _toJson(WishlistItem item) => {
  'productId': item.productId,
  'handle': item.handle,
  if (item.variantId != null) 'variantId': item.variantId,
  'addedAt': (item.addedAt ?? DateTime.now()).toIso8601String(),
};
