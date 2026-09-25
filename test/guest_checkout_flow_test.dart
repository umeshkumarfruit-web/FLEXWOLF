import 'package:flexwolf/core/storage/local_storage.dart';
import 'package:flexwolf/features/account/data/account_providers.dart';
import 'package:flexwolf/features/account/domain/customer_account_repository.dart';
import 'package:flexwolf/features/checkout/domain/checkout_result.dart';
import 'package:flexwolf/features/checkout/presentation/cart_screen.dart';
import 'package:flexwolf/features/checkout/presentation/checkout_screen.dart';
import 'package:flexwolf/features/shop/data/cart_controller.dart';
import 'package:flexwolf/features/shop/data/shop_providers.dart';
import 'package:flexwolf/features/shop/data/public_cart_repository.dart';
import 'package:flexwolf/features/shop/domain/cart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('guest opens cart and starts checkout without an account', (
    tester,
  ) async {
    final storage = InMemoryLocalStorage();
    final cart = CartController(
      repository: PublicCartRepository(storage),
      storage: storage,
    );
    await cart.addLine(
      const CartLineInput(
        merchandiseId: 'gid://shopify/ProductVariant/123',
        quantity: 1,
        title: 'Flex Tee',
        variantTitle: 'Black / M',
      ),
    );
    final checkout = _RecordingCheckoutCoordinator();
    final router = GoRouter(
      initialLocation: '/cart',
      routes: [
        GoRoute(path: '/cart', builder: (_, _) => const CartScreen()),
        GoRoute(path: '/checkout', builder: (_, _) => const CheckoutScreen()),
        GoRoute(path: '/shop', builder: (_, _) => const Scaffold()),
      ],
    );
    addTearDown(() {
      router.dispose();
      cart.dispose();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          cartControllerProvider.overrideWithValue(cart),
          customerAccountRepositoryProvider.overrideWithValue(
            _GuestCustomerRepository(),
          ),
          checkoutCoordinatorProvider.overrideWithValue(checkout),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Flex Tee'), findsOneWidget);
    expect(find.text('YOUR BAG NEEDS AN ACCOUNT'), findsNothing);

    await tester.tap(find.text('Secure checkout'));
    await tester.pumpAndSettle();
    expect(find.text('Guest checkout'), findsOneWidget);
    expect(find.text('Continue to payment'), findsOneWidget);

    await tester.tap(find.text('Continue to payment'));
    await tester.pumpAndSettle();
    expect(checkout.request, isNotNull);
    expect(checkout.request!.customerAccessToken, isNull);
    expect(checkout.request!.cart.totalQuantity, 1);
  });
}

class _GuestCustomerRepository extends Fake
    implements CustomerAccountRepository {
  @override
  Future<CustomerSession?> restoreSession() async => null;
}

class _RecordingCheckoutCoordinator extends Fake
    implements CheckoutCoordinator {
  CheckoutStartRequest? request;

  @override
  Future<CheckoutResult> start(CheckoutStartRequest request) async {
    this.request = request;
    return const CheckoutResult.cancelled();
  }
}
