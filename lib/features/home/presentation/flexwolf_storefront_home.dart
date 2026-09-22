import 'dart:async';

import 'package:flexwolf/app/router/route_names.dart';
import 'package:flexwolf/core/widgets/app_badge.dart';
import 'package:flexwolf/core/widgets/app_price.dart';
import 'package:flexwolf/core/widgets/app_product_card_shell.dart';
import 'package:flexwolf/core/widgets/app_quick_add_button.dart';
import 'package:flexwolf/core/widgets/app_remote_image.dart';
import 'package:flexwolf/core/widgets/shopify_image_url.dart';
import 'package:flexwolf/features/shop/data/shop_providers.dart';
import 'package:flexwolf/features/account/presentation/customer_auth_guard.dart';
import 'package:flexwolf/features/shop/domain/cart.dart';
import 'package:flexwolf/features/shop/domain/pagination.dart';
import 'package:flexwolf/features/shop/domain/product.dart';
import 'package:flexwolf/features/shop/domain/product_variant.dart';
import 'package:flexwolf/features/wishlist/data/wishlist_providers.dart';
import 'package:flexwolf/features/wishlist/domain/wishlist.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class FlexwolfStorefrontHome extends StatelessWidget {
  const FlexwolfStorefrontHome({super.key});
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: CustomScrollView(
        primary: false,
        cacheExtent: 500,
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                const _SaleCountdown(),
                const _AnnouncementBar(),
                InkWell(
                  onTap: () => context.goNamed(
                    AppRouteNames.collection,
                    pathParameters: const {'handle': 'summer-sale'},
                  ),
                  child: const _ReferenceCrop(
                    asset: 'assets/images/flexwolf-home-reference.jpeg',
                    top: 610,
                    bottom: 1380,
                  ),
                ),
                const _ShopAllStrip(),
              ],
            ),
          ),
          const _HomeCatalogGrid(),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _SaleCountdown extends StatefulWidget {
  const _SaleCountdown();
  @override
  State<_SaleCountdown> createState() => _SaleCountdownState();
}

class _SaleCountdownState extends State<_SaleCountdown> {
  late final Timer _timer;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final remaining = DateTime(
      now.year,
      now.month,
      now.day + 1,
    ).difference(now);
    String two(int value) => value.toString().padLeft(2, '0');
    return Container(
      color: const Color(0xff1b1b1b),
      height: 76,
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SUMMER SALE', style: _saleLabel),
                SizedBox(height: 7),
                Text('UP TO 45% OFF', style: _saleLabel),
              ],
            ),
          ),
          Row(
            children: [
              _CountdownUnit(two(remaining.inHours), 'HRS'),
              const _Dots(),
              _CountdownUnit(two(remaining.inMinutes % 60), 'MIN'),
              const _Dots(),
              _CountdownUnit(two(remaining.inSeconds % 60), 'SEC'),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnnouncementBar extends StatelessWidget {
  const _AnnouncementBar();
  @override
  Widget build(BuildContext context) => Container(
    height: 44,
    color: const Color(0xff1b1b1b),
    padding: const EdgeInsets.symmetric(horizontal: 23),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Icon(Icons.chevron_left, color: Colors.white, size: 24),
        Flexible(
          child: FittedBox(
            child: Text(
              'EASY 60-DAY RETURNS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 3.1,
              ),
            ),
          ),
        ),
        Icon(Icons.chevron_right, color: Colors.white, size: 24),
      ],
    ),
  );
}

const _saleLabel = TextStyle(
  color: Colors.white,
  fontSize: 10,
  fontWeight: FontWeight.w700,
  letterSpacing: 1.2,
);

class _CountdownUnit extends StatelessWidget {
  const _CountdownUnit(this.value, this.label);
  final String value;
  final String label;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: 5),
      Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    ],
  );
}

class _Dots extends StatelessWidget {
  const _Dots();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.only(left: 7, right: 7, bottom: 15),
    child: Text(
      ':',
      style: TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _ReferenceCrop extends StatelessWidget {
  const _ReferenceCrop({
    required this.asset,
    required this.top,
    required this.bottom,
  });
  final String asset;
  final double top;
  final double bottom;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final scale = width / 720;
      return SizedBox(
        width: width,
        height: (bottom - top) * scale,
        child: ClipRect(
          child: Stack(
            children: [
              Positioned(
                left: 0,
                top: -top * scale,
                width: width,
                child: Image.asset(asset, fit: BoxFit.fitWidth),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _ShopAllStrip extends StatelessWidget {
  const _ShopAllStrip();
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => context.goNamed(AppRouteNames.shop),
          child: const Text(
            'SHOP ALL',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'MENS',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.3,
          ),
        ),
      ],
    ),
  );
}

class _HomeCatalogGrid extends ConsumerStatefulWidget {
  const _HomeCatalogGrid();
  @override
  ConsumerState<_HomeCatalogGrid> createState() => _HomeCatalogGridState();
}

class _HomeCatalogGridState extends ConsumerState<_HomeCatalogGrid> {
  late Future<PaginatedResult<ProductSummary>> _future;
  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => _future = ref
      .read(productRepositoryProvider)
      .fetchProducts(const PaginationRequest(first: 250));
  @override
  Widget build(BuildContext context) =>
      FutureBuilder<PaginatedResult<ProductSummary>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
            );
          }
          if (snapshot.hasError || snapshot.data == null) {
            return SliverToBoxAdapter(
              child: Center(
                child: TextButton(
                  onPressed: () => setState(_load),
                  child: const Text('Products unavailable. Tap to retry'),
                ),
              ),
            );
          }
          final all = snapshot.data!.items;
          if (all.isEmpty) {
            return const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Products are temporarily unavailable.'),
              ),
            );
          }
          final prime = _picks(all, const [
            'boxy-heavyweight-tee',
            '365-crew-tee',
            'flexwolf-alphaskin-full-sleeve-tee',
            'flexwolf-core-oversized-tee',
          ]);
          final justIn = _picks(all, const [
            'mens-performance-stringer',
            'cloud-flex-joggers',
            'airflow-performance-tank',
            'boxy-heavyweight-tee',
          ]);
          final bottoms = all
              .where((p) {
                final name = '${p.title} ${p.productType ?? ''}'.toLowerCase();
                return name.contains('short') ||
                    name.contains('jogger') ||
                    name.contains('cargo');
              })
              .take(5)
              .toList();
          final performance = _picks(all, const [
            'apex-2-in-1-shorts-5',
            'apex-training-shorts',
            'flexwolf-alphaskin-compression-tees',
          ]);
          final edit =
              _byHandle(all, 'wolfmark-wrap-oversized-tee') ?? prime.first;
          final feature = _byHandle(all, 'flex-arm-tank') ?? justIn.first;
          return SliverList.list(
            children: [
              _CategoryGrid(products: all),
              const SizedBox(height: 28),
              _FeatureProduct(product: feature),
              const SizedBox(height: 40),
              _ProductRail(
                title: 'PRIME STRENGTH',
                products: prime,
                handle: 'all-products',
                tabs: const ['T-SHIRTS', 'BOTTOMWEAR'],
              ),
              const SizedBox(height: 39),
              _Campaign(
                imageUrl: edit.featuredImage?.url,
                title: 'THE WOLF EDIT',
                handle: 'graphic-collection',
              ),
              const SizedBox(height: 39),
              _ProductRail(
                title: 'JUST IN',
                products: justIn,
                handle: 'new-arrivals',
              ),
              const SizedBox(height: 39),
              _ProductRail(
                title: 'BOTTOMWEAR',
                products: bottoms.isEmpty ? performance : bottoms,
                handle: 'shorts',
              ),
              const SizedBox(height: 39),
              const _PerformanceBanner(),
              const SizedBox(height: 39),
              _ProductRail(
                title: 'EVERYDAY PERFORMANCE',
                products: performance,
                handle: 'best-seller',
              ),
              const SizedBox(height: 45),
              const _HomeFooter(),
            ],
          );
        },
      );
}

ProductSummary? _byHandle(List<ProductSummary> all, String handle) {
  for (final p in all) {
    if (p.handle == handle) return p;
  }
  return null;
}

List<ProductSummary> _picks(List<ProductSummary> all, List<String> handles) {
  final result = <ProductSummary>[];
  for (final h in handles) {
    final p = _byHandle(all, h);
    if (p != null) result.add(p);
  }
  for (final p in all) {
    if (result.length >= 5) break;
    if (!result.any((item) => item.id == p.id)) result.add(p);
  }
  return result;
}

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.products});
  final List<ProductSummary> products;
  @override
  Widget build(BuildContext context) {
    const categories = [
      ('Hoodie & Crew Neck', 'hoodies', 'hoodie'),
      ('T-Shirts', 't-shirts', 'tee'),
      ('Tank Tops', 'gym-vest', 'tank'),
      ('Bottomwear', 'shorts', 'short'),
      ('SUMMER SALE', 'summer-sale', 'jogger'),
      ('Graphic Collection', 'graphic-collection', 'graphic'),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = (constraints.maxWidth - 16) / 3;
          return Wrap(
            spacing: 8,
            runSpacing: 18,
            children: [
              for (final c in categories)
                SizedBox(
                  width: width,
                  child: InkWell(
                    onTap: () => context.goNamed(
                      AppRouteNames.collection,
                      pathParameters: {'handle': c.$2},
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: AspectRatio(
                            aspectRatio: .77,
                            child: _HomeImage(
                              url: _categoryImage(products, c.$3),
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          c.$1,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: c.$1 == 'SUMMER SALE'
                                ? const Color(0xffd73c29)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

String? _categoryImage(List<ProductSummary> all, String term) {
  for (final p in all) {
    if (p.title.toLowerCase().contains(term) && p.featuredImage != null) {
      return p.featuredImage!.url;
    }
  }
  return all.first.featuredImage?.url;
}

class _HomeImage extends StatelessWidget {
  const _HomeImage({required this.url});
  final String? url;
  @override
  Widget build(BuildContext context) {
    if (url == null || !url!.startsWith('https://')) {
      return const ColoredBox(
        color: Color(0xffeeeeee),
        child: Center(child: Icon(Icons.image_outlined, color: Colors.grey)),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final decodeWidth =
            (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
                .ceil()
                .clamp(64, 1200);
        return CachedNetworkImage(
          imageUrl: shopifyImageUrlForWidth(url!, decodeWidth),
          fit: BoxFit.cover,
          memCacheWidth: decodeWidth,
          filterQuality: FilterQuality.low,
          useOldImageOnUrlChange: true,
          fadeInDuration: Duration.zero,
          fadeOutDuration: Duration.zero,
          placeholder: (context, url) => const ColoredBox(
            color: Color(0xffeeeeee),
          ),
          errorWidget: (context, url, error) => const ColoredBox(
            color: Color(0xffeeeeee),
            child: Center(child: Icon(Icons.image_outlined, color: Colors.grey)),
          ),
        );
      },
    );
  }
}

class _FeatureProduct extends StatelessWidget {
  const _FeatureProduct({required this.product});
  final ProductSummary product;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.goNamed(
      AppRouteNames.product,
      pathParameters: {'handle': product.handle},
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: .93,
          child: _HomeImage(url: product.featuredImage?.url),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  product.title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .6,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ProductRail extends StatelessWidget {
  const _ProductRail({
    required this.title,
    required this.products,
    required this.handle,
    this.tabs = const [],
  });
  final String title;
  final List<ProductSummary> products;
  final String handle;
  final List<String> tabs;
  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    final cardWidth = (MediaQuery.sizeOf(context).width * .44).clamp(
      145.0,
      230.0,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 27,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              InkWell(
                onTap: () => context.goNamed(
                  AppRouteNames.collection,
                  pathParameters: {'handle': handle},
                ),
                child: const Text(
                  'VIEW ALL  >',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (tabs.isNotEmpty) ...[
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++) ...[
                  if (i > 0) const SizedBox(width: 27),
                  InkWell(
                    onTap: () => context.goNamed(
                      AppRouteNames.collection,
                      pathParameters: {
                        'handle': i == 0 ? 't-shirts' : 'shorts',
                      },
                    ),
                    child: Text(
                      tabs[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        decoration: i == 0
                            ? TextDecoration.underline
                            : TextDecoration.none,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
        const SizedBox(height: 17),
        SizedBox(
          height: cardWidth / .48,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) => SizedBox(
              width: cardWidth,
              child: StorefrontProductCard(product: products[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _Campaign extends StatelessWidget {
  const _Campaign({
    required this.title,
    required this.imageUrl,
    required this.handle,
  });
  final String title;
  final String? imageUrl;
  final String handle;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.goNamed(
      AppRouteNames.collection,
      pathParameters: {'handle': handle},
    ),
    child: SizedBox(
      height: 400,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _HomeImage(url: imageUrl),
          const ColoredBox(color: Color(0x55000000)),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 34),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.3,
                    ),
                  ),
                  const SizedBox(height: 19),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 36,
                      vertical: 13,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Text(
                      'SHOP NOW',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PerformanceBanner extends StatelessWidget {
  const _PerformanceBanner();
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.goNamed(
      AppRouteNames.collection,
      pathParameters: const {'handle': 'best-seller'},
    ),
    child: SizedBox(
      height: 470,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _HomeImage(
            url: 'https://flexwolf.co/cdn/shop/files/new_banner_21.065.2026.png?v=1781989121&width=900',
          ),
          const ColoredBox(color: Color(0x77000000)),
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 0, 25, 35),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LOOK BETTER.\nTRAIN HARDER.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 17),
                const Text(
                  'Premium athletic apparel engineered for comfort and performance.',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(height: 19),
                const Text(
                  '\u2713  BUILT FOR PERFORMANCE\n\u2713  DESIGNED FOR COMFORT\n\u2713  MADE TO MOVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 23),
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 15,
                  ),
                  child: const Text(
                    'SHOP BEST SELLERS',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _HomeFooter extends StatelessWidget {
  const _HomeFooter();
  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xff151515),
    padding: const EdgeInsets.fromLTRB(22, 30, 22, 32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FooterRow('CONNECT'),
        const _FooterRow('ABOUT US'),
        const SizedBox(height: 28),
        const Text(
          'FLEXWOLF',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'TRAIN HARD. STAY WILD.',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 10,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 25),
        const Row(
          children: [
            Icon(Icons.camera_alt_outlined, color: Colors.white, size: 23),
            SizedBox(width: 22),
            Icon(Icons.facebook, color: Colors.white, size: 23),
            SizedBox(width: 22),
            Icon(Icons.play_circle_outline, color: Colors.white, size: 23),
          ],
        ),
        const SizedBox(height: 28),
        const Text(
          'SECURE PAYMENTS',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 10,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 30),
        const Text(
          '(c) FLEXWOLF',
          style: TextStyle(color: Colors.white60, fontSize: 10),
        ),
      ],
    ),
  );
}

class _FooterRow extends StatelessWidget {
  const _FooterRow(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    collapsedIconColor: Colors.white,
    iconColor: Colors.white,
    title: Text(
      label,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
    ),
    children: [
      Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label == 'CONNECT'
                ? 'Follow FLEXWOLF on our social channels.'
                : 'Performance apparel made for every training day.',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
      ),
    ],
  );
}

class StorefrontProductCard extends ConsumerStatefulWidget {
  const StorefrontProductCard({
    required this.product,
    this.onProductTap,
    super.key,
  });
  final ProductSummary product;
  final ValueChanged<ProductSummary>? onProductTap;

  @override
  ConsumerState<StorefrontProductCard> createState() =>
      _StorefrontProductCardState();
}

class _StorefrontProductCardState extends ConsumerState<StorefrontProductCard> {
  String? _selectedColor;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final colors = product.variants
        .map((v) => v.color)
        .whereType<String>()
        .toSet()
        .toList();
    final variant =
        product.variants
            .where((v) => _selectedColor == null || v.color == _selectedColor)
            .firstOrNull ??
        product.variants.firstOrNull;
    final image = variant?.image ?? product.featuredImage;
    final subtitle = [
      variant?.color,
      variant?.size,
    ].whereType<String>().join(' / ');
    return AppProductCardShell(
      title: product.title,
      subtitle: subtitle.isEmpty ? null : subtitle,
      footer: colors.isEmpty
          ? null
          : SizedBox(
              height: 28,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: colors.length > 4 ? 5 : colors.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  if (index == 4 && colors.length > 4) {
                    return InkWell(
                      onTap: () => _showAllColors(context, colors),
                      child: Center(
                        child: Text(
                          '+${colors.length - 4}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    );
                  }
                  final color = colors[index];
                  return Tooltip(
                    message: color,
                    child: InkWell(
                      onTap: () => setState(() => _selectedColor = color),
                      borderRadius: BorderRadius.zero,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.rectangle,
                          color: _swatchColor(color),
                          border: Border.all(
                            color: (_selectedColor ?? colors.first) == color
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.grey.shade400,
                            width: (_selectedColor ?? colors.first) == color
                                ? 2.5
                                : 1,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
      badge: product.availableForSale
          ? const AppBadge(label: 'NEW')
          : const AppBadge(label: 'SOLD OUT'),
      onTap: () => widget.onProductTap == null
          ? context.goNamed(
              AppRouteNames.product,
              pathParameters: {'handle': product.handle},
            )
          : widget.onProductTap!(product),
      onWishlist: () async {
        await ref
            .read(wishlistRepositoryProvider)
            .toggle(
              WishlistItem(
                productId: product.id,
                handle: product.handle,
                variantId: variant?.id,
                product: product,
                addedAt: DateTime.now(),
              ),
            );
        ref.invalidate(wishlistProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Wishlist updated')));
        }
      },
      image: image == null
          ? const ColoredBox(color: Color(0xffeeeeee))
          : Stack(
              fit: StackFit.expand,
              children: [
                AppRemoteImage(
                  imageUrl: image.url,
                  semanticLabel: image.altText ?? product.title,
                  aspectRatio: .8,
                ),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: AppQuickAddButton(
                    onPressed: () => _quickAdd(context, product, variant),
                  ),
                ),
              ],
            ),
      price: variant == null
          ? const Text('Price unavailable')
          : AppPrice(
              price: _money(
                variant.price.currencyCode,
                variant.price.amount.value,
              ),
              compareAtPrice: variant.compareAtPrice == null
                  ? null
                  : _money(
                      variant.compareAtPrice!.currencyCode,
                      variant.compareAtPrice!.amount.value,
                    ),
            ),
    );
  }

  void _showAllColors(BuildContext context, List<String> colors) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('CHOOSE A COLOR'),
              const SizedBox(height: 16),
              Flexible(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final color in colors)
                        ChoiceChip(
                          label: Text(color),
                          selected: (_selectedColor ?? colors.first) == color,
                          avatar: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _swatchColor(color),
                              border: Border.all(color: Colors.grey.shade400),
                            ),
                          ),
                          onSelected: (_) {
                            setState(() => _selectedColor = color);
                            Navigator.pop(sheetContext);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _quickAdd(
    BuildContext context,
    ProductSummary product,
    ProductVariant? selected,
  ) async {
    final candidates = product.variants
        .where(
          (v) =>
              v.availableForSale &&
              (selected?.color == null || v.color == selected?.color),
        )
        .toList();
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('This color is sold out')));
      return;
    }
    final sizes = candidates.map((v) => v.size).whereType<String>().toSet();
    ProductVariant? variant = candidates.first;
    if (sizes.length > 1) {
      variant = await showModalBottomSheet<ProductVariant>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(title: Text('CHOOSE A SIZE')),
              for (final candidate in candidates)
                ListTile(
                  title: Text(candidate.size ?? candidate.title ?? 'Default'),
                  trailing: Text(
                    _money(
                      candidate.price.currencyCode,
                      candidate.price.amount.value,
                    ),
                  ),
                  onTap: () => Navigator.pop(sheetContext, candidate),
                ),
            ],
          ),
        ),
      );
    }
    if (variant == null || !context.mounted) return;
    await _addToCart(context, product, variant);
  }

  Future<void> _addToCart(
    BuildContext context,
    ProductSummary product,
    ProductVariant variant,
  ) async {
    final session = await requireCustomerSession(
      context,
      ref,
      message: 'Sign in or create an account before adding items to your bag.',
    );
    if (session == null || !context.mounted) return;
    try {
      await ref
          .read(cartControllerProvider)
          .addLine(
            CartLineInput(
              merchandiseId: variant.id,
              quantity: 1,
              title: product.title,
              variantTitle: variant.title,
              price: variant.price,
              imageUrl: variant.image?.url ?? product.featuredImage?.url,
            ),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.title} added to cart'),
            action: SnackBarAction(
              label: 'VIEW BAG',
              onPressed: () => context.push('/cart'),
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not add this item. Try again.')),
        );
      }
    }
  }

  static Color _swatchColor(String name) {
    final color = name.toLowerCase();
    if (color.contains('white') || color.contains('cloud')) return Colors.white;
    if (color.contains('black') || color.contains('charcoal')) {
      return Colors.black;
    }
    if (color.contains('red') || color.contains('crimson')) {
      return Colors.red.shade700;
    }
    if (color.contains('blue') || color.contains('navy')) {
      return Colors.blue.shade700;
    }
    if (color.contains('green') ||
        color.contains('olive') ||
        color.contains('sage')) {
      return Colors.green.shade600;
    }
    if (color.contains('gray') || color.contains('grey')) return Colors.grey;
    if (color.contains('brown') || color.contains('mocha')) return Colors.brown;
    if (color.contains('pink')) return Colors.pink.shade200;
    if (color.contains('yellow')) return Colors.yellow.shade600;
    return Colors.grey.shade300;
  }

  static String _money(String currency, String amount) =>
      '${currency == 'INR' ? 'Rs.' : currency} $amount';
}
