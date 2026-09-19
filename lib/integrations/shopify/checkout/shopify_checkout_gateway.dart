class ShopifyCheckoutSession {
  const ShopifyCheckoutSession({
    required this.checkoutUrl,
    required this.cartId,
  });

  final Uri checkoutUrl;
  final String cartId;
}

abstract interface class ShopifyCheckoutGateway {
  Future<void> presentCheckout(ShopifyCheckoutSession session);
}

class CheckoutKitNotConfigured implements ShopifyCheckoutGateway {
  const CheckoutKitNotConfigured();

  @override
  Future<void> presentCheckout(ShopifyCheckoutSession session) {
    throw UnsupportedError(
      'Checkout Kit bridge is not configured in this phase.',
    );
  }
}
