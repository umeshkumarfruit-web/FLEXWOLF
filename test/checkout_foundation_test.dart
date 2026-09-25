import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/storage/local_storage.dart';
import 'package:flexwolf/features/account/domain/customer_account_repository.dart';
import 'package:flexwolf/features/checkout/data/native_checkout_kit_bridge.dart';
import 'package:flexwolf/features/checkout/data/shopify_checkout_coordinator.dart';
import 'package:flexwolf/features/checkout/domain/checkout_result.dart';
import 'package:flexwolf/features/shop/data/shop_providers.dart';
import 'package:flexwolf/features/shop/data/cart_controller.dart';
import 'package:flexwolf/features/shop/domain/cart.dart';
import 'package:flexwolf/features/shop/domain/money.dart';
import 'package:flexwolf/integrations/analytics/analytics_boundary.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  const checkoutChannel = MethodChannel('com.flexwolf.flexwolf/checkout_kit');

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      checkoutChannel,
      null,
    );
  });

  test('checkout review uses Shopify cart totals without tax calculation', () {
    final cart = _cart();
    final review = CheckoutReview.fromCart(
      cart,
      CheckoutStartRequest(
        cart: cart,
        discountCodes: const ['FLEX10'],
        market: const CheckoutMarket(countryCode: 'US', currencyCode: 'USD'),
      ),
    );

    expect(review.totalQuantity, 2);
    expect(review.lines.single.title, 'Flex Tee');
    expect(review.subtotal?.amount.toString(), '50.00');
    expect(review.finalTotal?.amount.toString(), '45.00');
    expect(review.taxTotal, isNull);
    expect(review.discountCodes, const ['FLEX10']);
  });

  test('checkout validates shipping address before handoff', () async {
    final coordinator = ShopifyCheckoutCoordinator(
      cartRepository: _CartRepository(_cart()),
      presenter: const CheckoutNotConfiguredPresenter(),
    );

    expect(
      coordinator.prepare(
        CheckoutStartRequest(
          cart: _cart(),
          shippingAddress: const CustomerAddressInput(
            firstName: 'Flex',
            lastName: 'Wolf',
            address1: '',
            city: 'Los Angeles',
            country: 'US',
            zip: '90001',
          ),
        ),
      ),
      throwsFormatException,
    );
  });

  test('checkout prepare coalesces duplicate in-flight requests', () async {
    final repository = _CartRepository(_cart(), delayFetch: true);
    final coordinator = ShopifyCheckoutCoordinator(
      cartRepository: repository,
      presenter: const CheckoutNotConfiguredPresenter(),
    );

    final request = CheckoutStartRequest(cart: _cart());
    await Future.wait([
      coordinator.prepare(request),
      coordinator.prepare(request),
    ]);

    expect(repository.fetchCount, 1);
  });

  test('web checkout opens the exact Shopify checkout URL', () async {
    Uri? opened;
    final presenter = ShopifyWebCheckoutPresenter(
      launchCheckout: (uri) async {
        opened = uri;
        return true;
      },
    );
    final checkoutUrl = Uri.parse(
      'https://example.myshopify.com/checkouts/cn/abc',
    );

    final result = await presenter.present(
      CheckoutSessionRequest(checkoutUrl: checkoutUrl),
    );

    expect(opened, checkoutUrl);
    expect(result.status, CheckoutResultStatus.launched);
    expect(result.isSuccessfulPurchase, isFalse);
  });

  test('web checkout blocks non-HTTPS checkout URLs', () async {
    var launched = false;
    final presenter = ShopifyWebCheckoutPresenter(
      launchCheckout: (_) async {
        launched = true;
        return true;
      },
    );

    await expectLater(
      presenter.present(
        CheckoutSessionRequest(
          checkoutUrl: Uri.parse('http://example.test/checkout'),
        ),
      ),
      throwsA(
        isA<AppException>().having(
          (error) => error.code,
          'code',
          'https_required',
        ),
      ),
    );
    expect(launched, isFalse);
  });

  test('native checkout returns the completed Shopify order id', () async {
    MethodCall? receivedCall;
    binding.defaultBinaryMessenger.setMockMethodCallHandler(checkoutChannel, (
      call,
    ) async {
      receivedCall = call;
      return <String, Object?>{
        'status': 'completed',
        'orderId': 'gid://shopify/Order/42',
      };
    });

    final result = await const MethodChannelCheckoutKitBridge().present(
      CheckoutSessionRequest(
        checkoutUrl: Uri.parse('https://checkout.flexwolf.test/session'),
      ),
    );

    expect(receivedCall?.method, 'presentCheckout');
    expect(receivedCall?.arguments, {
      'checkoutUrl': 'https://checkout.flexwolf.test/session',
    });
    expect(result.orderId, 'gid://shopify/Order/42');
    expect(result.isSuccessfulPurchase, isTrue);
  });

  test('native checkout reports cancellation without a purchase', () async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      checkoutChannel,
      (_) async => <String, Object?>{'status': 'cancelled'},
    );

    final result = await const MethodChannelCheckoutKitBridge().present(
      CheckoutSessionRequest(
        checkoutUrl: Uri.parse('https://checkout.flexwolf.test/session'),
      ),
    );

    expect(result.status, CheckoutResultStatus.cancelled);
    expect(result.isSuccessfulPurchase, isFalse);
  });

  test(
    'cart reloads product lines when Shopify add response is partial',
    () async {
      final repository = _PartialAddCartRepository(_cart());
      final controller = CartController(
        repository: repository,
        storage: InMemoryLocalStorage(),
      );

      final result = await controller.addLine(
        const CartLineInput(merchandiseId: 'variant-1', quantity: 2),
      );

      expect(repository.fetchCount, 1);
      expect(result.lines.single.title, 'Flex Tee');
      expect(controller.cart?.lines.single.title, 'Flex Tee');
    },
  );

  test('bundle variants are sent to Shopify in one cart mutation', () async {
    final repository = _CartRepository(_cart());
    final controller = CartController(
      repository: repository,
      storage: InMemoryLocalStorage(),
    );

    await controller.addLines(const [
      CartLineInput(merchandiseId: 'black-medium', quantity: 2),
      CartLineInput(merchandiseId: 'red-medium', quantity: 1),
    ]);

    expect(repository.addCalls, 1);
    expect(repository.lastAddedLines.map((line) => line.quantity), [2, 1]);
  });

  test(
    'native checkout blocks non-HTTPS URLs before opening Android',
    () async {
      var called = false;
      binding.defaultBinaryMessenger.setMockMethodCallHandler(checkoutChannel, (
        _,
      ) async {
        called = true;
        return null;
      });

      await expectLater(
        const MethodChannelCheckoutKitBridge().present(
          CheckoutSessionRequest(
            checkoutUrl: Uri.parse('http://checkout.flexwolf.test/session'),
          ),
        ),
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            'https_required',
          ),
        ),
      );
      expect(called, isFalse);
    },
  );

  test('checkout analytics track allowed events only', () async {
    final analytics = _Analytics();
    final presenter = AnalyticsCheckoutPresenter(
      presenter: const _ClosedPresenter(),
      analytics: analytics,
    );
    await presenter.present(
      CheckoutSessionRequest(
        checkoutUrl: Uri.parse('https://checkout.flexwolf.test'),
        cartId: 'cart-1',
        review: CheckoutReview.fromCart(
          _cart(),
          CheckoutStartRequest(cart: _cart(), discountCodes: const ['FLEX10']),
        ),
      ),
    );

    expect(analytics.events, const [
      AppAnalyticsEvents.checkoutStarted,
      AppAnalyticsEvents.discountApplied,
      AppAnalyticsEvents.checkoutAbandoned,
    ]);
  });
}

CartSummary _cart() => CartSummary(
  id: 'cart-1',
  checkoutUrl: Uri.parse('https://checkout.flexwolf.test'),
  totalQuantity: 2,
  subtotal: Money(amount: DecimalAmount.parse('50.00'), currencyCode: 'USD'),
  total: Money(amount: DecimalAmount.parse('45.00'), currencyCode: 'USD'),
  lines: [
    CartLineSummary(
      id: 'line-1',
      merchandiseId: 'variant-1',
      title: 'Flex Tee',
      variantTitle: 'Black / M',
      quantity: 2,
      price: Money(amount: DecimalAmount.parse('25.00'), currencyCode: 'USD'),
    ),
  ],
);

class _CartRepository implements CartRepository {
  _CartRepository(this.cart, {this.delayFetch = false});
  final CartSummary cart;
  final bool delayFetch;
  int fetchCount = 0;
  int addCalls = 0;
  List<CartLineInput> lastAddedLines = const [];

  @override
  Future<CartSummary> createCart({CartBuyerIdentity? buyerIdentity}) async =>
      cart;

  @override
  Future<CartSummary?> fetchCart(String cartId) async {
    fetchCount += 1;
    if (delayFetch) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    return cart;
  }

  @override
  Future<CartSummary> addLines(String cartId, List<CartLineInput> lines) async {
    addCalls += 1;
    lastAddedLines = lines;
    return cart;
  }

  @override
  Future<CartSummary> removeLines(String cartId, List<String> lineIds) async =>
      cart;

  @override
  Future<CartSummary> updateLines(
    String cartId,
    List<CartLineInput> lines,
  ) async => cart;
}

class _PartialAddCartRepository implements CartRepository {
  _PartialAddCartRepository(this.cart);

  final CartSummary cart;
  int fetchCount = 0;

  @override
  Future<CartSummary> createCart({CartBuyerIdentity? buyerIdentity}) async =>
      CartSummary(id: cart.id, checkoutUrl: cart.checkoutUrl, totalQuantity: 0);

  @override
  Future<CartSummary> addLines(
    String cartId,
    List<CartLineInput> lines,
  ) async => CartSummary(
    id: cart.id,
    checkoutUrl: cart.checkoutUrl,
    totalQuantity: cart.totalQuantity,
  );

  @override
  Future<CartSummary?> fetchCart(String cartId) async {
    fetchCount += 1;
    return cart;
  }

  @override
  Future<CartSummary> removeLines(String cartId, List<String> lineIds) async =>
      cart;

  @override
  Future<CartSummary> updateLines(
    String cartId,
    List<CartLineInput> lines,
  ) async => cart;
}

class _ClosedPresenter implements CheckoutPresenter {
  const _ClosedPresenter();

  @override
  Future<CheckoutResult> present(CheckoutSessionRequest request) async =>
      const CheckoutResult.closed();
}

class _Analytics implements AnalyticsGateway {
  final events = <String>[];

  @override
  Future<void> track(AnalyticsEvent event) async {
    events.add(event.name);
  }
}
