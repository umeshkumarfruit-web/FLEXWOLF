import 'package:flexwolf/app/router/route_names.dart';
import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/services/service_registry.dart';
import 'package:flexwolf/core/widgets/app_badge.dart';
import 'package:flexwolf/core/widgets/app_button.dart';
import 'package:flexwolf/core/widgets/app_error_state.dart';
import 'package:flexwolf/core/widgets/app_loading_indicator.dart';
import 'package:flexwolf/core/widgets/app_price.dart';
import 'package:flexwolf/core/widgets/app_product_card_shell.dart';
import 'package:flexwolf/core/widgets/app_remote_image.dart';
import 'package:flexwolf/features/engagement/data/engagement_providers.dart';
import 'package:flexwolf/features/engagement/domain/engagement_models.dart';
import 'package:flexwolf/features/engagement/presentation/engagement_widgets.dart';
import 'package:flexwolf/features/account/presentation/customer_auth_guard.dart';
import 'package:flexwolf/features/reviews/presentation/product_reviews_section.dart';
import 'package:flexwolf/features/shop/data/shop_providers.dart';
import 'package:flexwolf/features/shop/domain/cart.dart';
import 'package:flexwolf/features/shop/domain/catalog_cache.dart';
import 'package:flexwolf/features/shop/domain/money.dart';
import 'package:flexwolf/features/shop/domain/product.dart';
import 'package:flexwolf/features/shop/domain/pagination.dart';
import 'package:flexwolf/features/wishlist/data/wishlist_providers.dart';
import 'package:flexwolf/features/wishlist/domain/wishlist.dart';
import 'package:flexwolf/features/shop/domain/product_media.dart';
import 'package:flexwolf/features/shop/domain/product_variant.dart';
import 'package:flexwolf/features/support/domain/support_models.dart';
import 'package:flexwolf/features/support/presentation/support_screen.dart';
import 'package:flexwolf/integrations/analytics/analytics_boundary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final productDetailProvider = FutureProvider.autoDispose
    .family<ProductSummary?, String>((ref, handle) {
      return ref.watch(productRepositoryProvider).fetchProductByHandle(handle);
    });

final relatedProductsProvider = FutureProvider.autoDispose
    .family<List<ProductSummary>, ProductSummary>((ref, product) async {
      final cache = ref.watch(shopCatalogCacheProvider);
      final key = '${cache.policy.environmentKey}:related:${product.id}';
      final cached = cache.read(key);
      if (cached != null) {
        return cached.result.items
            .where((item) => item.id != product.id)
            .take(6)
            .toList(growable: false);
      }
      final result = await ref
          .watch(productRepositoryProvider)
          .fetchProducts(const PaginationRequest(first: 12));
      cache.write(key, CachedPage(result: result, cachedAt: DateTime.now()));
      return result.items
          .where((item) => item.id != product.id)
          .take(6)
          .toList(growable: false);
    });

class ProductPage extends ConsumerStatefulWidget {
  const ProductPage({required this.handle, super.key});
  final String handle;
  @override
  ConsumerState<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends ConsumerState<ProductPage> {
  ProductVariant? _variant;
  String? _color;
  String? _size;
  int _qty = 1;
  bool _busy = false;
  var _tracked = false;

  @override
  void didUpdateWidget(covariant ProductPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.handle == widget.handle) return;
    _variant = null;
    _color = null;
    _size = null;
    _qty = 1;
    _busy = false;
    _tracked = false;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(productDetailProvider(widget.handle));
    return async.when(
      loading: () => const _ProductSkeleton(),
      error: (e, s) => AppErrorState(
        error: e is AppException ? e : mapUnknownException(e),
        onRetry: () => ref.invalidate(productDetailProvider(widget.handle)),
      ),
      data: (p) {
        if (p == null) {
          return const AppErrorState(
            error: AppException(
              kind: AppErrorKind.unavailable,
              message: 'Product was not found.',
              code: 'product_not_found',
            ),
          );
        }
        _trackView(p);
        _variant ??= _initialVariant(p);
        _color ??= _variant?.color;
        _size ??= _variant?.size;
        final colors = p.variants
            .map((v) => v.color)
            .whereType<String>()
            .toSet()
            .toList();
        final sizes = p.variants
            .where((v) => _color == null || v.color == _color)
            .map((v) => v.size)
            .whereType<String>()
            .toSet()
            .toList();
        final compare = _variant?.compareAtPrice;
        final sale =
            _variant != null && isDiscountedPrice(_variant!.price, compare);
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppButton.text(
                    label: 'Back',
                    icon: Icons.arrow_back,
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.shop);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _Gallery(product: p, variant: _variant),
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      const AppBadge(
                        label: 'TOP SELLER',
                        tone: AppBadgeTone.neutral,
                      ),
                      const AppBadge(
                        label: '60-DAY GUARANTEE',
                        tone: AppBadgeTone.neutral,
                      ),
                      if (sale)
                        const AppBadge(label: 'SALE', tone: AppBadgeTone.sale),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    p.title,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppPrice(
                    price: _money(_variant?.price),
                    compareAtPrice: sale ? _money(compare) : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if ((p.description ?? '').isNotEmpty)
                    Text(
                      p.description!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  if (colors.isNotEmpty)
                    _ChoiceRow(
                      title: 'Color',
                      values: colors,
                      selected: _color,
                      onSelected: (v) {
                        setState(() {
                          _color = v;
                          _variant = p.variants.firstWhere(
                            (x) => x.color == v,
                            orElse: () => _variant!,
                          );
                          _size = _variant?.size;
                        });
                        _track('variant_selected');
                      },
                    ),
                  if (sizes.isNotEmpty)
                    _ChoiceRow(
                      title: 'Size',
                      values: sizes,
                      selected: _size,
                      onSelected: (v) {
                        setState(() {
                          _size = v;
                          _variant = p.variants.firstWhere(
                            (x) => x.color == _color && x.size == v,
                            orElse: () => _variant!,
                          );
                        });
                        _track('size_selected');
                      },
                    ),
                  AppButton.text(
                    label: 'Size Chart',
                    icon: Icons.straighten,
                    onPressed: () => _sheet(
                      'Size Chart',
                      'Client size chart content pending.',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _stockText(_variant),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if ((_variant?.quantityAvailable ?? 99) <= 3 &&
                      (_variant?.availableForSale ?? false))
                    const Text('Low stock'),
                  if (!(_variant?.availableForSale ?? p.availableForSale))
                    EngagementAlertButton(
                      product: p,
                      kind: EngagementAlertKind.backInStock,
                    ),
                  EngagementAlertButton(
                    product: p,
                    kind: EngagementAlertKind.priceDrop,
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _qty > 1
                            ? () => setState(() => _qty--)
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text('$_qty'),
                      IconButton(
                        onPressed: () => setState(() => _qty++),
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: AppButton.secondary(
                          label: 'Add To Cart',
                          icon: Icons.shopping_bag_outlined,
                          onPressed: _busy ? null : () => _add(false),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      IconButton.outlined(
                        tooltip: 'Add to wishlist',
                        onPressed: _busy ? null : () => _toggleWishlist(p),
                        icon: const Icon(Icons.favorite_border),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton.primary(
                      label: _busy ? 'Opening Checkout...' : 'Buy Now',
                      icon: Icons.flash_on,
                      semanticLabel: 'Buy ${p.title} now with Shopify checkout',
                      onPressed: _busy || !(_variant?.availableForSale ?? false)
                          ? null
                          : () => _add(true),
                    ),
                  ),
                  AppButton.text(
                    label: 'Product Support',
                    icon: Icons.support_agent,
                    semanticLabel: 'Contact support about ',
                    onPressed: () => _openProductSupport(p),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _Details(product: p),
                  const SizedBox(height: AppSpacing.lg),
                  ProductReviewsSection(product: p),
                  const SizedBox(height: AppSpacing.lg),
                  _RelatedProducts(product: p),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _openProductSupport(ProductSummary product) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SupportScreen(
        reference: SupportReference(
          productId: product.id,
          productTitle: product.title,
        ),
      ),
    );
  }

  Future<void> _toggleWishlist(ProductSummary product) async {
    await ref
        .read(wishlistRepositoryProvider)
        .toggle(
          WishlistItem(
            productId: product.id,
            handle: product.handle,
            variantId: _variant?.id,
            addedAt: DateTime.now(),
            product: product,
          ),
        );
    ref.invalidate(wishlistProvider);
    _track(AppAnalyticsEvents.productAddedToWishlist);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Wishlist updated')));
    }
  }

  Future<void> _add(bool buyNow) async {
    if (_variant == null || !(_variant!.availableForSale)) {
      _sheet('Sold out', 'Please choose an available variant.');
      return;
    }
    setState(() => _busy = true);
    try {
      final session = await requireCustomerSession(
        context,
        ref,
        message:
            'Sign in or create an account before adding items to your bag.',
      );
      if (session == null) return;
      final product = ref
          .read(productDetailProvider(widget.handle))
          .asData
          ?.value;
      await ref
          .read(cartControllerProvider)
          .addLine(
            CartLineInput(
              merchandiseId: _variant!.id,
              quantity: _qty,
              title: product?.title,
              variantTitle: _variant!.title,
              price: _variant!.price,
              imageUrl: _variant!.image?.url ?? product?.featuredImage?.url,
            ),
          );
      _track(buyNow ? 'buy_now' : 'add_to_cart');
      if (buyNow && mounted) {
        context.push('/checkout');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added $_qty item(s) to cart'),
            action: SnackBarAction(
              label: 'View bag',
              onPressed: () => context.push('/cart'),
            ),
          ),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        _sheet(
          'Cart unavailable',
          error is AppException ? error.message : 'Cart could not be updated.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _trackView(ProductSummary p) {
    if (_tracked) {
      return;
    }
    _tracked = true;
    ref.read(engagementRepositoryProvider).trackRecentlyViewed(p);
    ref
        .read(analyticsGatewayProvider)
        .track(
          AnalyticsEvent(
            name: AppAnalyticsEvents.recentlyViewed,
            parameters: {'productId': p.id, 'handle': p.handle},
          ),
        );
    ref
        .read(analyticsGatewayProvider)
        .track(
          AnalyticsEvent(
            name: 'product_viewed',
            parameters: {'handle': p.handle, 'productId': p.id},
          ),
        );
  }

  void _track(String name) =>
      ref.read(analyticsGatewayProvider).track(AnalyticsEvent(name: name));
  void _sheet(String title, String body) => showModalBottomSheet<void>(
    context: context,
    builder: (c) => Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(c).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Text(body),
        ],
      ),
    ),
  );
}

class _RelatedProducts extends ConsumerWidget {
  const _RelatedProducts({required this.product});

  final ProductSummary product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final related = ref.watch(relatedProductsProvider(product));
    return Semantics(
      container: true,
      label: 'Related products',
      explicitChildNodes: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Related Products',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.md),
          related.when(
            loading: () => const _RelatedProductsSkeleton(),
            error: (error, stackTrace) => AppRetryState(
              title: 'Related products unavailable',
              message: error is AppException
                  ? error.userMessage
                  : 'Try again later.',
              onRetry: () => ref.invalidate(relatedProductsProvider(product)),
            ),
            data: (products) {
              if (products.isEmpty) return const SizedBox.shrink();
              return SizedBox(
                height: 292,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: products.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final item = products[index];
                    final variant = item.variants.isEmpty
                        ? null
                        : item.variants.first;
                    return SizedBox(
                      width: 172,
                      child: AppProductCardShell(
                        title: item.title,
                        image: item.featuredImage == null
                            ? const Center(child: Icon(Icons.image_outlined))
                            : AppRemoteImage(
                                imageUrl: item.featuredImage!.url,
                                semanticLabel:
                                    item.featuredImage!.altText ?? item.title,
                              ),
                        subtitle: item.availableForSale
                            ? 'Available'
                            : 'Sold out',
                        price: AppPrice(price: _money(variant?.price)),
                        semanticLabel: 'Open related product ${item.title}',
                        onTap: () => context.goNamed(
                          AppRouteNames.product,
                          pathParameters: {'handle': item.handle},
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RelatedProductsSkeleton extends StatelessWidget {
  const _RelatedProductsSkeleton();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Expanded(child: AppSkeletonLoader(height: 220)),
      SizedBox(width: AppSpacing.md),
      Expanded(child: AppSkeletonLoader(height: 220)),
    ],
  );
}

class _Gallery extends StatelessWidget {
  const _Gallery({required this.product, this.variant});
  final ProductSummary product;
  final ProductVariant? variant;
  @override
  Widget build(BuildContext context) {
    final imgs = [
      if (variant?.image != null) variant!.image!,
      ...product.images,
    ];
    if (imgs.isEmpty && product.featuredImage != null) {
      imgs.add(product.featuredImage!);
    }
    return SizedBox(
      height: 420,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: PageView(
          children: [
            for (final i in imgs)
              AppRemoteImage(
                imageUrl: i.url,
                semanticLabel: i.altText ?? product.title,
              ),
            for (final m in product.media.where(
              (m) => m.kind == ProductMediaKind.video && m.previewImage != null,
            ))
              Stack(
                children: [
                  AppRemoteImage(
                    imageUrl: m.previewImage!.url,
                    semanticLabel: m.altText ?? product.title,
                  ),
                  const Center(child: Icon(Icons.play_circle, size: 64)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.title,
    required this.values,
    required this.selected,
    required this.onSelected,
  });
  final String title;
  final List<String> values;
  final String? selected;
  final ValueChanged<String> onSelected;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title),
      Wrap(
        spacing: AppSpacing.xs,
        children: [
          for (final v in values)
            ChoiceChip(
              label: Text(v),
              selected: v == selected,
              onSelected: (_) => onSelected(v),
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.md),
    ],
  );
}

class _Details extends StatelessWidget {
  const _Details({required this.product});
  final ProductSummary product;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final description = (product.description ?? '').trim();
    final rows = <String, String>{
      'Product Details': description.isEmpty
          ? (product.productType ?? 'Details pending from Shopify.')
          : description,
      if ((product.productType ?? '').isNotEmpty) 'Type': product.productType!,
      if ((product.vendor ?? '').isNotEmpty) 'Brand': product.vendor!,
      if (product.tags.isNotEmpty) 'Tags': product.tags.join(', '),
      'Shipping': 'Calculated at checkout.',
      'Returns': 'See FLEXWOLF return policy.',
    };

    return Material(
      color: colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.sm),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Text(
              'Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          for (final e in rows.entries)
            Theme(
              data: Theme.of(context)
                  .copyWith(dividerColor: colors.outlineVariant),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                ),
                childrenPadding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.md,
                ),
                title: Text(
                  e.key,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      e.value,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ProductSkeleton extends StatelessWidget {
  const _ProductSkeleton();
  @override
  Widget build(BuildContext context) => const Column(
    children: [
      AppSkeletonLoader(height: 360),
      SizedBox(height: AppSpacing.lg),
      AppSkeletonLoader(height: 24),
      SizedBox(height: AppSpacing.sm),
      AppSkeletonLoader(height: 18),
    ],
  );
}

ProductVariant? _initialVariant(ProductSummary product) {
  for (final variant in product.variants) {
    if (variant.availableForSale) {
      return variant;
    }
  }
  return product.variants.isEmpty ? null : product.variants.first;
}

String _money(Money? m) =>
    m == null ? 'Price unavailable' : '${m.currencyCode} ${m.amount.value}';
String _stockText(ProductVariant? v) {
  if (v == null) return 'Select options';
  if (!v.availableForSale) return 'Sold out';
  final q = v.quantityAvailable;
  return q == null ? 'In stock' : '$q in stock';
}
