import 'package:flexwolf/features/shop/domain/product.dart';

class WishlistItem {
  const WishlistItem({
    required this.productId,
    required this.handle,
    this.variantId,
    this.addedAt,
    this.product,
  });

  final String productId;
  final String handle;
  final String? variantId;
  final DateTime? addedAt;
  final ProductSummary? product;

  String get key => variantId == null ? productId : '$productId::$variantId';

  WishlistItem copyWith({ProductSummary? product}) => WishlistItem(
    productId: productId,
    handle: handle,
    variantId: variantId,
    addedAt: addedAt,
    product: product ?? this.product,
  );
}

class WishlistState {
  const WishlistState({
    this.items = const <WishlistItem>[],
    this.isSynced = false,
  });

  final List<WishlistItem> items;
  final bool isSynced;
  int get count => items.length;
  bool containsProduct(String productId, {String? variantId}) => items.any(
    (item) => item.productId == productId && item.variantId == variantId,
  );
}

abstract interface class WishlistRepository {
  Future<WishlistState> load({String? customerId});
  Future<WishlistState> add(WishlistItem item, {String? customerId});
  Future<WishlistState> remove(
    String productId, {
    String? variantId,
    String? customerId,
  });
  Future<WishlistState> toggle(WishlistItem item, {String? customerId});
  Future<WishlistState> mergeGuestIntoCustomer(String customerId);
}
