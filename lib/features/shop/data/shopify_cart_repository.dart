import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/features/shop/data/queries/storefront_queries.dart';
import 'package:flexwolf/features/shop/domain/cart.dart';
import 'package:flexwolf/features/shop/domain/money.dart';
import 'package:flexwolf/integrations/shopify/graphql/shopify_graphql_client.dart';

class ShopifyCartRepository
    implements CartRepository, BuyerIdentityCartRepository {
  const ShopifyCartRepository(this._client);

  final ShopifyGraphqlClient _client;

  @override
  Future<CartSummary> createCart({CartBuyerIdentity? buyerIdentity}) async {
    final input = <String, Object?>{
      if (buyerIdentity != null)
        'buyerIdentity': _buyerIdentityInput(buyerIdentity),
    }..removeWhere((_, value) => value == null);
    final response = await _client.query(
      ShopifyGraphqlRequest(
        document: StorefrontQueries.cartCreate,
        operationName: 'CartCreate',
        variables: <String, Object?>{'input': input},
        isMutation: true,
      ),
    );
    return _cartFromMutation(response, 'cartCreate');
  }

  @override
  Future<CartSummary> addLines(String cartId, List<CartLineInput> lines) async {
    final response = await _client.query(
      ShopifyGraphqlRequest(
        document: StorefrontQueries.cartLinesAdd,
        operationName: 'CartLinesAdd',
        variables: <String, Object?>{
          'cartId': cartId,
          'lines': lines.map(_lineAddInput).toList(growable: false),
        },
        isMutation: true,
      ),
    );
    return _cartFromMutation(response, 'cartLinesAdd');
  }

  @override
  Future<CartSummary?> fetchCart(String cartId) async {
    final response = await _client.query(
      ShopifyGraphqlRequest(
        document: StorefrontQueries.cartById,
        operationName: 'CartById',
        variables: <String, Object?>{'id': cartId},
      ),
    );
    final cart = _dataMap(response)['cart'];
    return cart is Map<String, Object?> ? _cartFromJson(cart) : null;
  }

  @override
  Future<CartSummary> removeLines(String cartId, List<String> lineIds) async {
    final response = await _client.query(
      ShopifyGraphqlRequest(
        document: StorefrontQueries.cartLinesRemove,
        operationName: 'CartLinesRemove',
        variables: <String, Object?>{'cartId': cartId, 'lineIds': lineIds},
        isMutation: true,
      ),
    );
    return _cartFromMutation(response, 'cartLinesRemove');
  }

  @override
  Future<CartSummary> updateLines(
    String cartId,
    List<CartLineInput> lines,
  ) async {
    final response = await _client.query(
      ShopifyGraphqlRequest(
        document: StorefrontQueries.cartLinesUpdate,
        operationName: 'CartLinesUpdate',
        variables: <String, Object?>{
          'cartId': cartId,
          'lines': lines.map(_lineUpdateInput).toList(growable: false),
        },
        isMutation: true,
      ),
    );
    return _cartFromMutation(response, 'cartLinesUpdate');
  }

  @override
  Future<CartSummary> updateBuyerIdentity(
    String cartId,
    CartBuyerIdentity buyerIdentity,
  ) async {
    final response = await _client.query(
      ShopifyGraphqlRequest(
        document: StorefrontQueries.cartBuyerIdentityUpdate,
        operationName: 'CartBuyerIdentityUpdate',
        variables: <String, Object?>{
          'cartId': cartId,
          'buyerIdentity': _buyerIdentityInput(buyerIdentity),
        },
        isMutation: true,
      ),
    );
    return _cartFromMutation(response, 'cartBuyerIdentityUpdate');
  }
}

CartSummary _cartFromMutation(ShopifyGraphqlResponse response, String field) {
  final payload = _dataMap(response)[field];
  if (payload is! Map<String, Object?>) {
    throw const AppException(
      kind: AppErrorKind.api,
      message: 'Shopify cart response is missing mutation payload.',
      code: 'shopify_cart_missing_payload',
    );
  }
  _throwUserErrors(payload['userErrors']);
  final cart = payload['cart'];
  if (cart is Map<String, Object?>) return _cartFromJson(cart);
  throw const AppException(
    kind: AppErrorKind.api,
    message: 'Shopify cart response is missing cart data.',
    code: 'shopify_cart_missing_cart',
  );
}

CartSummary _cartFromJson(Map<String, Object?> json) {
  final id = json['id'];
  final checkoutUrl = json['checkoutUrl'];
  final totalQuantity = json['totalQuantity'];
  if (id is! String || checkoutUrl is! String || totalQuantity is! int) {
    throw const FormatException('Invalid Shopify cart payload.');
  }
  return CartSummary(
    id: id,
    checkoutUrl: Uri.parse(checkoutUrl),
    totalQuantity: totalQuantity,
    buyerIdentity: _buyerIdentityFromJson(json['buyerIdentity']),
    subtotal: _moneyFromCost(json['cost'], 'subtotalAmount'),
    total: _moneyFromCost(json['cost'], 'totalAmount'),
    lines: _cartLinesFromJson(json['lines']),
  );
}

CartBuyerIdentity? _buyerIdentityFromJson(Object? value) {
  if (value is! Map<String, Object?>) return null;
  return CartBuyerIdentity(
    countryCode: value['countryCode']?.toString(),
    email: value['email']?.toString(),
    phone: value['phone']?.toString(),
  );
}

List<CartLineSummary> _cartLinesFromJson(Object? value) {
  if (value is! Map<String, Object?>) return const <CartLineSummary>[];
  final nodes = value['nodes'];
  if (nodes is! List) return const <CartLineSummary>[];
  return nodes
      .whereType<Map<String, Object?>>()
      .map(_cartLineFromJson)
      .toList(growable: false);
}

CartLineSummary _cartLineFromJson(Map<String, Object?> json) {
  final id = json['id'];
  final quantity = json['quantity'];
  final merchandise = json['merchandise'];
  if (id is! String ||
      quantity is! int ||
      merchandise is! Map<String, Object?>) {
    throw const FormatException('Invalid Shopify cart line payload.');
  }
  final merchandiseId = merchandise['id'];
  if (merchandiseId is! String) {
    throw const FormatException('Invalid Shopify cart merchandise payload.');
  }
  final product = merchandise['product'];
  return CartLineSummary(
    id: id,
    merchandiseId: merchandiseId,
    title: product is Map<String, Object?>
        ? product['title']?.toString() ?? ''
        : '',
    quantity: quantity,
    variantTitle: merchandise['title']?.toString(),
    price: merchandise['price'] is Map<String, Object?>
        ? Money.fromShopify(merchandise['price']! as Map<String, Object?>)
        : null,
    imageUrl: merchandise['image'] is Map<String, Object?>
        ? (merchandise['image']! as Map<String, Object?>)['url']?.toString()
        : null,
  );
}

Money? _moneyFromCost(Object? value, String field) {
  if (value is! Map<String, Object?>) return null;
  final money = value[field];
  return money is Map<String, Object?> ? Money.fromShopify(money) : null;
}

Map<String, Object?> _dataMap(ShopifyGraphqlResponse response) {
  final data = response.data;
  if (data is Map<String, Object?>) return data;
  throw const AppException(
    kind: AppErrorKind.api,
    message: 'Shopify response is missing data.',
    code: 'shopify_missing_data',
  );
}

void _throwUserErrors(Object? errors) {
  if (errors is! List || errors.isEmpty) return;
  final messages = errors
      .whereType<Map<String, Object?>>()
      .map((error) => error['message']?.toString())
      .whereType<String>()
      .where((message) => message.trim().isNotEmpty)
      .toList(growable: false);
  throw AppException(
    kind: AppErrorKind.api,
    message: messages.isEmpty
        ? 'Shopify rejected the cart request.'
        : messages.join(' '),
    code: 'shopify_cart_user_error',
    isRetryable: false,
  );
}

Map<String, Object?> _buyerIdentityInput(CartBuyerIdentity identity) {
  return <String, Object?>{
    if (identity.countryCode?.trim().isNotEmpty ?? false)
      'countryCode': identity.countryCode,
    if (identity.email?.trim().isNotEmpty ?? false) 'email': identity.email,
    if (identity.phone?.trim().isNotEmpty ?? false) 'phone': identity.phone,
    if (identity.customerAccessToken?.trim().isNotEmpty ?? false)
      'customerAccessToken': identity.customerAccessToken,
  };
}

Map<String, Object?> _lineAddInput(CartLineInput line) {
  return <String, Object?>{
    'merchandiseId': line.merchandiseId,
    'quantity': line.quantity,
  };
}

Map<String, Object?> _lineUpdateInput(CartLineInput line) {
  return <String, Object?>{'id': line.merchandiseId, 'quantity': line.quantity};
}
