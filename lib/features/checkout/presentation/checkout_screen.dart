import 'package:flexwolf/app/router/route_names.dart';
import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/layout/responsive_page_padding.dart';
import 'package:flexwolf/core/widgets/app_button.dart';
import 'package:flexwolf/core/widgets/app_error_state.dart';
import 'package:flexwolf/core/widgets/app_loading_indicator.dart';
import 'package:flexwolf/core/widgets/app_price.dart';
import 'package:flexwolf/features/account/data/account_providers.dart';
import 'package:flexwolf/features/account/domain/customer_account_repository.dart';
import 'package:flexwolf/features/checkout/domain/checkout_result.dart';
import 'package:flexwolf/features/shop/data/cart_controller.dart';
import 'package:flexwolf/features/shop/data/shop_providers.dart';
import 'package:flexwolf/features/shop/domain/cart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  late final CartController _cart;
  CustomerSession? _session;
  bool _loadingSession = true;
  bool _paying = false;
  CheckoutResult? _result;
  AppException? _error;

  @override
  void initState() {
    super.initState();
    _cart = ref.read(cartControllerProvider)..addListener(_changed);
    _loadSession();
  }

  @override
  void dispose() {
    _cart.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  Future<void> _loadSession() async {
    try {
      await _cart.restore();
      _session = await ref
          .read(customerAccountRepositoryProvider)
          .restoreSession();
    } catch (_) {
      // Account restore must not block guest checkout.
      _session = null;
    } finally {
      if (mounted) setState(() => _loadingSession = false);
    }
  }

  Future<void> _pay() async {
    final cart = _cart.cart;
    if (cart == null || cart.totalQuantity == 0 || _paying) return;
    setState(() {
      _paying = true;
      _error = null;
    });
    try {
      String? email;
      if (_session != null) {
        try {
          email =
              (await ref.read(customerAccountRepositoryProvider).fetchProfile())
                  ?.email;
        } catch (_) {
          // Profile prefill is optional; Shopify checkout stays available.
        }
      }
      final result = await ref
          .read(checkoutCoordinatorProvider)
          .start(
            CheckoutStartRequest(
              cart: cart,
              email: email,
              customerAccessToken: _session?.canAuthenticateShopify == true
                  ? _session!.accessToken
                  : null,
            ),
          );
      if (!mounted) return;
      if (result.isSuccessfulPurchase) {
        await _cart.clear();
        setState(() => _result = result);
      } else if (result.status == CheckoutResultStatus.failed) {
        setState(() {
          _error = AppException(
            kind: AppErrorKind.checkout,
            message: result.errorMessage ?? 'Payment could not be completed.',
            code: 'checkout_failed',
            isRetryable: true,
          );
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error is AppException ? error : mapUnknownException(error);
        });
      }
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = _cart.cart;
    return Scaffold(
      appBar: AppBar(
        title: const Text('CHECKOUT'),
        leading: IconButton(
          tooltip: 'Back to cart',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/cart'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: ResponsivePagePadding(
          child: _result?.isSuccessfulPurchase == true
              ? _OrderSuccess(result: _result!)
              : _loadingSession
              ? const Center(
                  child: AppLoadingIndicator(label: 'Preparing checkout'),
                )
              : cart == null || cart.lines.isEmpty
              ? Center(
                  child: AppButton.primary(
                    label: 'Return to shop',
                    onPressed: () => context.go(AppRoutes.shop),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  children: [
                    Text(
                      'ORDER REVIEW',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    for (final line in cart.lines) _ReviewLine(line: line),
                    const Divider(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('TOTAL'),
                        AppPrice(
                          price: cart.total == null
                              ? 'Calculated securely'
                              : '${cart.total!.currencyCode} ${cart.total!.amount}',
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.verified_user_outlined),
                      title: Text(
                        _session == null ? 'Guest checkout' : 'Secure checkout',
                      ),
                      subtitle: Text(
                        'Complete your order securely on FLEXWOLF checkout.',
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      AppErrorState(error: _error!, onRetry: _pay),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    AppButton.primary(
                      label: _paying
                          ? 'Opening secure paymentÃ¢â‚¬Â¦'
                          : 'Continue to payment',
                      icon: Icons.lock_outline,
                      onPressed: _paying ? null : _pay,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.security, size: 16),
                        SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            'Payment is processed securely by Shopify.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ReviewLine extends StatelessWidget {
  const _ReviewLine({required this.line});
  final CartLineSummary line;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(line.title),
    subtitle: Text('${line.variantTitle ?? ''} Ã‚Â· Qty ${line.quantity}'),
    trailing: line.price == null
        ? null
        : AppPrice(price: '${line.price!.currencyCode} ${line.price!.amount}'),
  );
}

class _OrderSuccess extends StatelessWidget {
  const _OrderSuccess({required this.result});
  final CheckoutResult result;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, size: 72),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'ORDER CONFIRMED',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(result.orderName ?? 'Your order has been placed successfully.'),
        const SizedBox(height: AppSpacing.xl),
        AppButton.primary(
          label: 'Continue shopping',
          onPressed: () => context.go(AppRoutes.shop),
        ),
      ],
    ),
  );
}
