import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/storage/local_storage.dart';
import 'package:flexwolf/features/shop/domain/cart.dart';
import 'package:flutter/foundation.dart';

class CartController extends ChangeNotifier {
  CartController({
    required CartRepository repository,
    required LocalStorage storage,
  }) : this._(repository, storage);

  CartController._(this._repository, this._storage);

  static const storageKey = 'shopify.cart.id';

  final CartRepository _repository;
  final LocalStorage _storage;

  CartSummary? _cart;
  Object? _error;
  bool _loading = false;
  bool _restored = false;
  Future<void>? _restoreFuture;

  CartSummary? get cart => _cart;
  Object? get error => _error;
  bool get isLoading => _loading;
  int get itemCount => _cart?.totalQuantity ?? 0;
  bool get isEmpty => itemCount == 0;

  Future<void> restore() {
    final pending = _restoreFuture;
    if (pending != null) return pending;
    if (_restored) return Future<void>.value();
    _restored = true;
    final restoreFuture = _run(() async {
      final cartId = await _storage.readString(storageKey);
      if (cartId == null || cartId.trim().isEmpty) return;
      try {
        _cart = await _repository.fetchCart(cartId);
      } catch (_) {
        _cart = null;
      }
      if (_cart == null) await _storage.remove(storageKey);
    });
    _restoreFuture = restoreFuture;
    return restoreFuture.whenComplete(() => _restoreFuture = null);
  }

  Future<CartSummary> addLine(CartLineInput line) async {
    return addLines(<CartLineInput>[line]);
  }

  Future<CartSummary> addLines(List<CartLineInput> lines) async {
    if (lines.isEmpty) {
      throw ArgumentError.value(
        lines,
        'lines',
        'At least one cart line is required.',
      );
    }
    await restore();
    CartSummary? result;
    await _run(() async {
      await _ensureCart();
      result = await _repository.addLines(_cart!.id, lines);
      // Shopify mutations can occasionally return a partial cart payload while
      // the cart itself already contains the new line. Re-fetch in that case so
      // the bag never shows an item count without the corresponding products.
      if (result!.totalQuantity > 0 && result!.lines.isEmpty) {
        result = await _repository.fetchCart(result!.id) ?? result;
      }
      await _save(result!);
    });
    return result!;
  }

  Future<void> updateQuantity(CartLineSummary line, int quantity) async {
    await restore();
    if (_cart == null) return;
    if (quantity <= 0) return removeLine(line.id);
    await _run(() async {
      final next = await _repository.updateLines(_cart!.id, <CartLineInput>[
        CartLineInput(merchandiseId: line.id, quantity: quantity),
      ]);
      await _save(next);
    });
  }

  Future<void> removeLine(String lineId) async {
    await restore();
    if (_cart == null) return;
    await _run(() async {
      final next = await _repository.removeLines(_cart!.id, <String>[lineId]);
      await _save(next);
    });
  }

  Future<void> refresh() async {
    await restore();
    final current = _cart;
    if (current == null) return;
    await _run(() async {
      final next = await _repository.fetchCart(current.id);
      if (next == null) {
        await clear();
      } else {
        await _save(next);
      }
    });
  }

  Future<void> clear() async {
    _cart = null;
    _error = null;
    await _storage.remove(storageKey);
    notifyListeners();
  }

  Future<void> _ensureCart() async {
    if (_cart != null) return;
    await _save(await _repository.createCart());
  }

  Future<void> _save(CartSummary cart) async {
    _cart = cart;
    await _storage.writeString(storageKey, cart.id);
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_loading) {
      throw const AppException(
        kind: AppErrorKind.api,
        message: 'Cart is already updating. Please wait.',
        code: 'cart_update_in_progress',
        isRetryable: true,
      );
    }
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      _error = error;
      rethrow;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
