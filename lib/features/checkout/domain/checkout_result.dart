import 'package:url_launcher/url_launcher.dart';
import 'package:flexwolf/core/security/security_policy.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/features/account/domain/customer.dart';
import 'package:flexwolf/features/account/domain/customer_account_repository.dart';
import 'package:flexwolf/features/shop/domain/cart.dart';
import 'package:flexwolf/features/shop/domain/money.dart';

enum CheckoutResultStatus { launched, completed, cancelled, failed, closed }

class CheckoutResult {
  const CheckoutResult.launched()
    : status = CheckoutResultStatus.launched,
      orderId = null,
      orderName = null,
      errorMessage = null;

  const CheckoutResult.completed({this.orderId, this.orderName})
    : status = CheckoutResultStatus.completed,
      errorMessage = null;

  const CheckoutResult.cancelled()
    : status = CheckoutResultStatus.cancelled,
      orderId = null,
      orderName = null,
      errorMessage = null;

  const CheckoutResult.failed(this.errorMessage)
    : status = CheckoutResultStatus.failed,
      orderId = null,
      orderName = null;

  const CheckoutResult.closed()
    : status = CheckoutResultStatus.closed,
      orderId = null,
      orderName = null,
      errorMessage = null;

  final CheckoutResultStatus status;
  final String? orderId;
  final String? orderName;
  final String? errorMessage;

  bool get isSuccessfulPurchase =>
      status == CheckoutResultStatus.completed && orderId != null;
}

class CheckoutSessionRequest {
  const CheckoutSessionRequest({
    required this.checkoutUrl,
    this.cartId,
    this.review,
    this.customerAccessToken,
  });

  final Uri checkoutUrl;
  final String? cartId;
  final CheckoutReview? review;
  final String? customerAccessToken;
}

class CheckoutStartRequest {
  const CheckoutStartRequest({
    required this.cart,
    this.email,
    this.phone,
    this.shippingAddress,
    this.savedAddress,
    this.discountCodes = const <String>[],
    this.giftCardCodes = const <String>[],
    this.market,
    this.customerAccessToken,
  });

  final CartSummary cart;
  final String? email;
  final String? phone;
  final CustomerAddressInput? shippingAddress;
  final CustomerAddress? savedAddress;
  final List<String> discountCodes;
  final List<String> giftCardCodes;
  final CheckoutMarket? market;
  final String? customerAccessToken;

  bool get isLoggedIn => customerAccessToken?.trim().isNotEmpty ?? false;
}

class CheckoutMarket {
  const CheckoutMarket({
    this.countryCode,
    this.currencyCode,
    this.languageCode,
  });

  final String? countryCode;
  final String? currencyCode;
  final String? languageCode;
}

class CheckoutReview {
  const CheckoutReview({
    required this.cartId,
    required this.checkoutUrl,
    required this.totalQuantity,
    this.lines = const <CheckoutReviewLine>[],
    this.shippingAddress,
    this.shippingMethod,
    this.shippingCost,
    this.subtotal,
    this.discountTotal,
    this.taxTotal,
    this.finalTotal,
    this.discountCodes = const <String>[],
    this.giftCardCodes = const <String>[],
    this.market,
  });

  factory CheckoutReview.fromCart(
    CartSummary cart,
    CheckoutStartRequest request,
  ) {
    return CheckoutReview(
      cartId: cart.id,
      checkoutUrl: cart.checkoutUrl,
      totalQuantity: cart.totalQuantity,
      lines: cart.lines
          .map(
            (line) => CheckoutReviewLine(
              title: line.title,
              quantity: line.quantity,
              variantTitle: line.variantTitle,
              price: line.price,
            ),
          )
          .toList(growable: false),
      shippingAddress:
          request.savedAddress ?? _addressFromInput(request.shippingAddress),
      subtotal: cart.subtotal,
      finalTotal: cart.total,
      discountCodes: request.discountCodes,
      giftCardCodes: request.giftCardCodes,
      market: request.market,
    );
  }

  final String cartId;
  final Uri checkoutUrl;
  final int totalQuantity;
  final List<CheckoutReviewLine> lines;
  final CustomerAddress? shippingAddress;
  final String? shippingMethod;
  final Money? shippingCost;
  final Money? subtotal;
  final Money? discountTotal;
  final Money? taxTotal;
  final Money? finalTotal;
  final List<String> discountCodes;
  final List<String> giftCardCodes;
  final CheckoutMarket? market;
}

class CheckoutReviewLine {
  const CheckoutReviewLine({
    required this.title,
    required this.quantity,
    this.variantTitle,
    this.price,
  });

  final String title;
  final int quantity;
  final String? variantTitle;
  final Money? price;
}

abstract interface class CheckoutCoordinator {
  Future<CheckoutSessionRequest> prepare(CheckoutStartRequest request);

  Future<CheckoutResult> start(CheckoutStartRequest request);
}

abstract interface class CheckoutPresenter {
  Future<CheckoutResult> present(CheckoutSessionRequest request);
}

class CheckoutNotConfiguredPresenter implements CheckoutPresenter {
  const CheckoutNotConfiguredPresenter();

  @override
  Future<CheckoutResult> present(CheckoutSessionRequest request) async {
    return const CheckoutResult.failed(
      'Checkout Kit bridge is not configured yet.',
    );
  }
}

class ShopifyWebCheckoutPresenter implements CheckoutPresenter {
  const ShopifyWebCheckoutPresenter({this.launchCheckout = _launchCheckout});

  final Future<bool> Function(Uri uri) launchCheckout;

  @override
  Future<CheckoutResult> present(CheckoutSessionRequest request) async {
    SecurityPolicy.requireHttpsUri(
      request.checkoutUrl,
      context: 'Shopify checkout URL',
    );
    if (!await launchCheckout(request.checkoutUrl)) {
      throw const AppException(
        kind: AppErrorKind.checkout,
        message: 'Could not open Shopify checkout. Please try again.',
        code: 'checkout_browser_unavailable',
        isRetryable: true,
      );
    }
    return const CheckoutResult.launched();
  }
}

Future<bool> _launchCheckout(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.inAppBrowserView);
CustomerAddress? _addressFromInput(CustomerAddressInput? input) {
  if (input == null) return null;
  return CustomerAddress(
    id: 'pending-checkout-address',
    firstName: input.firstName,
    lastName: input.lastName,
    company: input.company,
    address1: input.address1,
    address2: input.address2,
    city: input.city,
    province: input.province,
    country: input.country,
    zip: input.zip,
    phone: input.phone,
  );
}
