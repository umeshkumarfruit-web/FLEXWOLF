import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/features/checkout/domain/checkout_result.dart';
import 'package:flexwolf/features/shop/domain/cart.dart';

class ShopifyCheckoutCoordinator implements CheckoutCoordinator {
  ShopifyCheckoutCoordinator({
    required CartRepository cartRepository,
    required CheckoutPresenter presenter,
  }) : this._(cartRepository, presenter);

  ShopifyCheckoutCoordinator._(this._cartRepository, this._presenter);

  final CartRepository _cartRepository;
  final CheckoutPresenter _presenter;
  Future<CheckoutSessionRequest>? _prepareInFlight;

  @override
  Future<CheckoutSessionRequest> prepare(CheckoutStartRequest request) {
    return _prepareInFlight ??= _prepare(request).whenComplete(() {
      _prepareInFlight = null;
    });
  }

  Future<CheckoutSessionRequest> _prepare(CheckoutStartRequest request) async {
    if (request.cart.totalQuantity <= 0) {
      throw const AppException(
        kind: AppErrorKind.checkout,
        message: 'Cart is empty.',
        code: 'checkout_empty_cart',
      );
    }
    request.shippingAddress?.validate();
    final buyerIdentity = CartBuyerIdentity(
      countryCode: request.market?.countryCode,
      email: request.email,
      phone: request.phone,
      customerAccessToken: request.customerAccessToken,
    );
    final cart =
        await _cartRepository.fetchCart(request.cart.id) ?? request.cart;
    final reviewedCart =
        _hasBuyerIdentity(buyerIdentity) &&
            _cartRepository is BuyerIdentityCartRepository
        ? await (_cartRepository as BuyerIdentityCartRepository)
              .updateBuyerIdentity(cart.id, buyerIdentity)
        : cart;
    return CheckoutSessionRequest(
      checkoutUrl: reviewedCart.checkoutUrl,
      cartId: reviewedCart.id,
      customerAccessToken: request.customerAccessToken,
      review: CheckoutReview.fromCart(reviewedCart, request),
    );
  }

  @override
  Future<CheckoutResult> start(CheckoutStartRequest request) async {
    final session = await prepare(request);
    return _presenter.present(session);
  }
}

bool _hasBuyerIdentity(CartBuyerIdentity identity) {
  return identity.countryCode != null ||
      identity.email != null ||
      identity.phone != null ||
      identity.customerAccessToken != null;
}
