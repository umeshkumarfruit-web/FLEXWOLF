import 'package:flexwolf/app/router/deep_link_contract.dart';
import 'package:flexwolf/app/router/route_names.dart';
import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/layout/responsive_page_padding.dart';
import 'package:flexwolf/core/widgets/app_button.dart';
import 'package:flexwolf/core/widgets/app_empty_state.dart';
import 'package:flexwolf/core/widgets/app_error_state.dart';
import 'package:flexwolf/core/widgets/app_loading_indicator.dart';
import 'package:flexwolf/core/widgets/app_price.dart';
import 'package:flexwolf/core/widgets/app_remote_image.dart';
import 'package:flexwolf/features/account/data/account_providers.dart';
import 'package:flexwolf/features/account/domain/customer_account_repository.dart';
import 'package:flexwolf/features/account/presentation/customer_auth_guard.dart';
import 'package:flexwolf/features/shop/data/cart_controller.dart';
import 'package:flexwolf/features/shop/data/shop_providers.dart';
import 'package:flexwolf/features/shop/domain/cart.dart';
import 'package:flexwolf/features/shop/domain/money.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  late final CartController _controller;
  CustomerSession? _session;
  bool _loadingSession = true;

  @override
  void initState() {
    super.initState();
    _controller = ref.read(cartControllerProvider)..addListener(_changed);
    _loadAuthenticatedCart();
  }

  Future<void> _loadAuthenticatedCart() async {
    _session = await ref.read(customerSessionProvider.future);
    if (_session != null) await _loadCart();
    if (mounted) setState(() => _loadingSession = false);
  }

  Future<void> _authenticate() async {
    final session = await requireCustomerSession(
      context,
      ref,
      message: 'Sign in or create an account to use your FLEXWOLF bag.',
    );
    if (session == null || !mounted) return;
    setState(() {
      _session = session;
      _loadingSession = true;
    });
    await _loadCart();
    if (mounted) setState(() => _loadingSession = false);
  }

  Future<void> _loadCart() async {
    await _controller.restore();
    if (_controller.itemCount > 0 &&
        (_controller.cart?.lines.isEmpty ?? true)) {
      await _controller.refresh();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cart = _controller.cart;
    return Scaffold(
      appBar: AppBar(
        title: const Text('YOUR BAG'),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.shop),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: ResponsivePagePadding(
          child: _loadingSession
              ? const Center(
                  child: AppLoadingIndicator(label: 'Checking your account'),
                )
              : _session == null
              ? _CartAuthenticationRequired(onAuthenticate: _authenticate)
              : _controller.isLoading && cart == null
              ? const Center(child: AppLoadingIndicator(label: 'Loading cart'))
              : cart == null || cart.lines.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppEmptyState(
                        title: 'Your bag is empty',
                        message: 'Find your next FLEXWOLF essential.',
                        icon: Icons.shopping_bag_outlined,
                      ),
                      SizedBox(
                        width: 220,
                        child: AppButton.primary(
                          label: 'Shop now',
                          onPressed: () => context.go(AppRoutes.shop),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    if (_controller.error != null)
                      AppErrorState(
                        error: _error(_controller.error!),
                        onRetry: _controller.refresh,
                      ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _controller.refresh,
                        child: ListView.separated(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          itemCount: cart.lines.length,
                          separatorBuilder: (_, _) => const Divider(height: 32),
                          itemBuilder: (_, index) => _CartLineTile(
                            line: cart.lines[index],
                            busy: _controller.isLoading,
                            onQuantityChanged: (quantity) => _controller
                                .updateQuantity(cart.lines[index], quantity),
                            onRemove: () =>
                                _controller.removeLine(cart.lines[index].id),
                          ),
                        ),
                      ),
                    ),
                    _CartSummary(
                      cart: cart,
                      busy: _controller.isLoading,
                      onCheckout: () => context.push(AppDeepLinks.checkout),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _CartAuthenticationRequired extends StatelessWidget {
  const _CartAuthenticationRequired({required this.onAuthenticate});

  final VoidCallback onAuthenticate;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.shopping_bag_outlined, size: 56),
        const SizedBox(height: AppSpacing.md),
        Text(
          'YOUR BAG NEEDS AN ACCOUNT',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Sign in or create a FLEXWOLF account to start shopping.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppButton.primary(
          label: 'Sign in or create account',
          icon: Icons.person_outline,
          onPressed: onAuthenticate,
        ),
      ],
    ),
  );
}

class _CartLineTile extends StatelessWidget {
  const _CartLineTile({
    required this.line,
    required this.busy,
    required this.onQuantityChanged,
    required this.onRemove,
  });

  final CartLineSummary line;
  final bool busy;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 104,
          height: 132,
          child: line.imageUrl == null
              ? const ColoredBox(
                  color: AppColors.neutral100,
                  child: Icon(Icons.image_outlined),
                )
              : AppRemoteImage(
                  imageUrl: line.imageUrl!,
                  semanticLabel: line.title,
                  aspectRatio: AppAspectRatios.productCard,
                ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(line.title, style: Theme.of(context).textTheme.titleMedium),
              if ((line.variantTitle ?? '').isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  line.variantTitle!,
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: AppColors.textSecondary),
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              if (line.price != null) AppPrice(price: _money(line.price)),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  IconButton.outlined(
                    visualDensity: VisualDensity.compact,
                    onPressed: busy || line.quantity <= 1
                        ? null
                        : () => onQuantityChanged(line.quantity - 1),
                    icon: const Icon(Icons.remove, size: 18),
                  ),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${line.quantity}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  IconButton.outlined(
                    visualDensity: VisualDensity.compact,
                    onPressed: busy
                        ? null
                        : () => onQuantityChanged(line.quantity + 1),
                    icon: const Icon(Icons.add, size: 18),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Remove ${line.title}',
                    onPressed: busy ? null : onRemove,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CartSummary extends StatelessWidget {
  const _CartSummary({
    required this.cart,
    required this.busy,
    required this.onCheckout,
  });

  final CartSummary cart;
  final bool busy;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SUBTOTAL · ${cart.totalQuantity} ITEMS',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                AppPrice(price: _money(cart.subtotal ?? cart.total)),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Shipping, taxes and discounts are calculated securely at checkout.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton.primary(
              label: 'Secure checkout',
              icon: Icons.lock_outline,
              onPressed: busy ? null : onCheckout,
            ),
          ],
        ),
      ),
    );
  }
}

String _money(Money? money) => money == null
    ? 'Calculated at checkout'
    : '${money.currencyCode} ${money.amount}';

AppException _error(Object error) =>
    error is AppException ? error : mapUnknownException(error);
