import 'package:flexwolf/app/router/route_names.dart';
import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/services/service_registry.dart';
import 'package:flexwolf/core/widgets/app_empty_state.dart';
import 'package:flexwolf/core/widgets/app_error_state.dart';
import 'package:flexwolf/core/widgets/app_loading_indicator.dart';
import 'package:flexwolf/core/widgets/app_price.dart';
import 'package:flexwolf/core/widgets/app_remote_image.dart';
import 'package:flexwolf/features/account/presentation/customer_auth_guard.dart';
import 'package:flexwolf/features/shop/data/shop_providers.dart';
import 'package:flexwolf/features/shop/domain/cart.dart';
import 'package:flexwolf/features/wishlist/data/wishlist_providers.dart';
import 'package:flexwolf/features/wishlist/domain/wishlist.dart';
import 'package:flexwolf/integrations/analytics/analytics_boundary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wishlistProvider);
    return Semantics(
      label: 'Wishlist',
      explicitChildNodes: true,
      child: state.when(
        loading: () =>
            const Center(child: AppSkeletonLoader(width: 240, height: 180)),
        error: (error, stack) => AppErrorState(
          error: error is AppException ? error : mapUnknownException(error),
          onRetry: () => ref.invalidate(wishlistProvider),
        ),
        data: (wishlist) {
          ref
              .read(analyticsGatewayProvider)
              .track(
                const AnalyticsEvent(name: AppAnalyticsEvents.wishlistViewed),
              );
          if (wishlist.items.isEmpty) {
            return const AppEmptyState(
              title: 'Wishlist is empty',
              message: 'Save products here while you shop.',
              icon: Icons.favorite_border,
            );
          }
          return ListView.builder(
            itemCount: wishlist.items.length + 1,
            itemBuilder: (context, index) => index == 0
                ? Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Text(
                      'Wishlist (${wishlist.count})',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  )
                : _WishlistTile(item: wishlist.items[index - 1]),
          );
        },
      ),
    );
  }
}

class _WishlistTile extends ConsumerWidget {
  const _WishlistTile({required this.item});
  final WishlistItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final product = item.product;
    final variant =
        product?.variants.where((v) => v.id == item.variantId).firstOrNull ??
        product?.variants.firstOrNull;
    return Semantics(
      label: 'Wishlist product ${product?.title ?? item.handle}',
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: SizedBox(
          width: 64,
          height: 64,
          child: product?.featuredImage == null
              ? const Icon(Icons.image_outlined)
              : AppRemoteImage(
                  imageUrl: product!.featuredImage!.url,
                  semanticLabel: product.title,
                ),
        ),
        title: Text(
          product?.title ?? item.handle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (variant != null) Text(variant.title ?? 'Default variant'),
            Text(
              product?.availableForSale ?? false ? 'Available' : 'Unavailable',
            ),
            if (variant != null)
              AppPrice(
                price: _money(variant.price),
                compareAtPrice: _moneyOrNull(variant.compareAtPrice),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          tooltip: 'Wishlist actions',
          onSelected: (value) async {
            if (value == 'open') {
              context.goNamed(
                AppRouteNames.product,
                pathParameters: <String, String>{
                  'handle': product?.handle ?? item.handle,
                },
              );
            }
            if (value == 'remove') {
              await ref
                  .read(wishlistRepositoryProvider)
                  .remove(item.productId, variantId: item.variantId);
              ref.invalidate(wishlistProvider);
              ref
                  .read(analyticsGatewayProvider)
                  .track(
                    const AnalyticsEvent(
                      name: AppAnalyticsEvents.productRemovedFromWishlist,
                    ),
                  );
            }
            if (value == 'cart' && variant != null) {
              if (!context.mounted) return;
              final session = await requireCustomerSession(
                context,
                ref,
                message:
                    'Sign in or create an account to move items to your bag.',
              );
              if (session == null) return;
              await ref
                  .read(cartControllerProvider)
                  .addLine(
                    CartLineInput(merchandiseId: variant.id, quantity: 1),
                  );
              await ref
                  .read(wishlistRepositoryProvider)
                  .remove(item.productId, variantId: item.variantId);
              ref.invalidate(wishlistProvider);
              ref
                  .read(analyticsGatewayProvider)
                  .track(
                    const AnalyticsEvent(
                      name: AppAnalyticsEvents.wishlistMoveToCart,
                    ),
                  );
              if (context.mounted) context.push('/cart');
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'open', child: Text('Open Product')),
            PopupMenuItem(value: 'cart', child: Text('Move to Cart')),
            PopupMenuItem(value: 'remove', child: Text('Remove')),
          ],
        ),
      ),
    );
  }
}

String _money(dynamic money) => '${money.currencyCode} ${money.amount}';
String? _moneyOrNull(dynamic money) => money == null ? null : _money(money);
