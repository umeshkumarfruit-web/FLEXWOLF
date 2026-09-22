import 'dart:convert';

import 'package:flexwolf/core/storage/local_storage.dart';
import 'package:flexwolf/features/shop/domain/cart.dart';
import 'package:flexwolf/features/shop/domain/money.dart';

/// Persists a guest bag and hands its real variant IDs to Shopify checkout.
class PublicCartRepository implements CartRepository {
  PublicCartRepository(this._storage);

  static const cartId = 'public-storefront-cart';
  static const _storageKey = 'public.cart.lines';
  final LocalStorage _storage;

  @override
  Future<CartSummary> createCart({CartBuyerIdentity? buyerIdentity}) async {
    await _save(const []);
    return _summary(const []);
  }

  @override
  Future<CartSummary?> fetchCart(String id) async {
    if (id != cartId) return null;
    return _summary(await _load());
  }

  @override
  Future<CartSummary> addLines(String id, List<CartLineInput> inputs) async {
    final lines = await _load();
    for (final input in inputs) {
      final index = lines.indexWhere((line) => line.id == input.merchandiseId);
      if (index < 0) {
        lines.add(
          CartLineSummary(
            id: input.merchandiseId,
            merchandiseId: input.merchandiseId,
            title: input.title ?? 'FLEXWOLF product',
            quantity: input.quantity,
            variantTitle: input.variantTitle,
            price: input.price,
            imageUrl: input.imageUrl,
          ),
        );
      } else {
        final old = lines[index];
        lines[index] = _copy(old, quantity: old.quantity + input.quantity);
      }
    }
    return _save(lines);
  }

  @override
  Future<CartSummary> updateLines(String id, List<CartLineInput> inputs) async {
    final lines = await _load();
    for (final input in inputs) {
      final index = lines.indexWhere((line) => line.id == input.merchandiseId);
      if (index >= 0)
        lines[index] = _copy(lines[index], quantity: input.quantity);
    }
    lines.removeWhere((line) => line.quantity <= 0);
    return _save(lines);
  }

  @override
  Future<CartSummary> removeLines(String id, List<String> lineIds) async {
    final lines = await _load();
    lines.removeWhere((line) => lineIds.contains(line.id));
    return _save(lines);
  }

  CartLineSummary _copy(CartLineSummary line, {required int quantity}) =>
      CartLineSummary(
        id: line.id,
        merchandiseId: line.merchandiseId,
        title: line.title,
        quantity: quantity,
        variantTitle: line.variantTitle,
        price: line.price,
        imageUrl: line.imageUrl,
      );

  Future<List<CartLineSummary>> _load() async {
    final raw = await _storage.readString(_storageKey);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded.whereType<Map<String, Object?>>().map((value) {
        final amount = value['price'] as String?;
        return CartLineSummary(
          id: value['id'] as String,
          merchandiseId: value['id'] as String,
          title: value['title'] as String? ?? 'FLEXWOLF product',
          quantity: value['quantity'] as int? ?? 1,
          variantTitle: value['variantTitle'] as String?,
          price: amount == null
              ? null
              : Money(amount: DecimalAmount.parse(amount), currencyCode: 'USD'),
          imageUrl: value['imageUrl'] as String?,
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<CartSummary> _save(List<CartLineSummary> lines) async {
    await _storage.writeString(
      _storageKey,
      jsonEncode([
        for (final line in lines)
          {
            'id': line.merchandiseId,
            'title': line.title,
            'quantity': line.quantity,
            'variantTitle': line.variantTitle,
            'price': line.price?.amount.value,
            'imageUrl': line.imageUrl,
          },
      ]),
    );
    return _summary(lines);
  }

  CartSummary _summary(List<CartLineSummary> lines) {
    final quantities = lines
        .map((line) {
          final variantId = line.merchandiseId.split('/').last;
          return '$variantId:${line.quantity}';
        })
        .join(',');
    final subtotal = lines.fold<double>(
      0,
      (sum, line) =>
          sum +
          (double.tryParse(line.price?.amount.value ?? '') ?? 0) *
              line.quantity,
    );
    return CartSummary(
      id: cartId,
      checkoutUrl: Uri.parse('https://flexwolf.co/cart/$quantities'),
      totalQuantity: lines.fold(0, (sum, line) => sum + line.quantity),
      subtotal: Money(
        amount: DecimalAmount.parse(subtotal.toStringAsFixed(2)),
        currencyCode: 'USD',
      ),
      lines: List.unmodifiable(lines),
    );
  }
}
