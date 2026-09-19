import 'package:flexwolf/features/shop/domain/money.dart';

class CartSummary {
  const CartSummary({
    required this.id,
    required this.checkoutUrl,
    required this.totalQuantity,
    this.buyerIdentity,
    this.subtotal,
    this.total,
    this.lines = const <CartLineSummary>[],
  });

  final String id;
  final Uri checkoutUrl;
  final int totalQuantity;
  final CartBuyerIdentity? buyerIdentity;
  final Money? subtotal;
  final Money? total;
  final List<CartLineSummary> lines;
}

class CartBuyerIdentity {
  const CartBuyerIdentity({
    this.countryCode,
    this.email,
    this.phone,
    this.customerAccessToken,
  });

  final String? countryCode;
  final String? email;
  final String? phone;
  final String? customerAccessToken;
}

abstract interface class CartRepository {
  Future<CartSummary> createCart({CartBuyerIdentity? buyerIdentity});

  Future<CartSummary> addLines(String cartId, List<CartLineInput> lines);

  Future<CartSummary> updateLines(String cartId, List<CartLineInput> lines);

  Future<CartSummary> removeLines(String cartId, List<String> lineIds);

  Future<CartSummary?> fetchCart(String cartId);
}

abstract interface class BuyerIdentityCartRepository {
  Future<CartSummary> updateBuyerIdentity(
    String cartId,
    CartBuyerIdentity buyerIdentity,
  );
}

class CartLineInput {
  const CartLineInput({required this.merchandiseId, required this.quantity});

  final String merchandiseId;
  final int quantity;
}

class CartLineSummary {
  const CartLineSummary({
    required this.id,
    required this.merchandiseId,
    required this.title,
    required this.quantity,
    this.variantTitle,
    this.price,
    this.imageUrl,
  });

  final String id;
  final String merchandiseId;
  final String title;
  final int quantity;
  final String? variantTitle;
  final Money? price;
  final String? imageUrl;
}
