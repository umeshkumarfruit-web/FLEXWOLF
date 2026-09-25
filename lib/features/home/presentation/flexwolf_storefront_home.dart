import 'dart:async';

import 'package:flexwolf/app/router/route_names.dart';
import 'package:flexwolf/core/widgets/app_badge.dart';
import 'package:flexwolf/core/widgets/app_price.dart';
import 'package:flexwolf/core/widgets/app_product_card_shell.dart';
import 'package:flexwolf/core/widgets/app_quick_add_button.dart';
import 'package:flexwolf/core/widgets/app_remote_image.dart';
import 'package:flexwolf/core/widgets/shopify_image_url.dart';
import 'package:flexwolf/features/shop/data/shop_providers.dart';
import 'package:flexwolf/features/home/presentation/home_feature_product.dart';
import 'package:flexwolf/features/shop/domain/cart.dart';
import 'package:flexwolf/features/shop/domain/pagination.dart';
import 'package:flexwolf/features/shop/domain/product.dart';
import 'package:flexwolf/features/shop/domain/product_variant.dart';
import 'package:flexwolf/features/wishlist/data/wishlist_providers.dart';
import 'package:flexwolf/features/wishlist/domain/wishlist.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class FlexwolfStorefrontHome extends StatelessWidget {
  const FlexwolfStorefrontHome({super.key});
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: CustomScrollView(
        primary: false,
        scrollCacheExtent: const ScrollCacheExtent.pixels(500),
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
          const SliverToBoxAdapter(child: _CategoryGrid()),
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
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
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 34, 16, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => context.goNamed(AppRouteNames.shop),
              child: const Text(
                'SHOP ALL',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  decoration: TextDecoration.underline,
                  decorationThickness: 2,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'MENS',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
      const Positioned(
        top: -18,
        left: 0,
        right: 0,
        child: Center(
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            child: Icon(Icons.keyboard_arrow_down, color: Colors.black),
          ),
        ),
      ),
    ],
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
          final bottoms = _picks(all, const [
            'off-duty-cargo-pants',
            'flex-embedded-fleece-joggers',
            'apex-2-in-1-shorts-5',
            'apex-training-shorts',
          ]);
          final performance = _picks(all, const [
            'apex-2-in-1-shorts-5',
            'apex-training-shorts',
            'flexwolf-alphaskin-compression-tees',
            'air-mesh-long-sleeve',
          ]);
          final feature = _byHandle(all, 'flex-arm-tank') ?? justIn.first;
          return SliverList.list(
            children: [
              HomeFeatureProduct(product: feature),
              const SizedBox(height: 40),
              _ProductRail(
                title: 'PRIME STRENGTH',
                products: prime,
                handle: 'compression-t-shirts',
                tabs: const ['T-SHIRTS', 'BOTTOMWEAR'],
                alternateProducts: bottoms,
                alternateHandle: 'shorts',
              ),
              const SizedBox(height: 39),
              const _Campaign(
                imageUrl: 'https://flexwolf.co/cdn/shop/files/wolf_edition_with_text_mobile.png?v=1781988758&width=900',
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
  const _CategoryGrid();
  @override
  Widget build(BuildContext context) {
    const categories = [
      (
        'Hoodie & Crew Neck',
        'winter-collection',
        'assets/images/home_category_hoodie.jpg',
      ),
      (
        'T-Shirts',
        'compression-t-shirts',
        'assets/images/home_category_tees.jpg',
      ),
      ('Tank Tops', 'gym-vest', 'assets/images/home_category_tanks.jpg'),
      ('Bottomwear', 'shorts', 'assets/images/home_category_bottomwear.jpg'),
      ('SUMMER SALE', 'summer-sale', ''),
      (
        'Graphic Collection',
        'graphic-collection',
        'assets/images/home_category_graphic.jpg',
      ),
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
                            aspectRatio: 168 / 232,
                            child: c.$2 == 'summer-sale'
                                ? const _SummerSaleTile()
                                : Image.asset(c.$3, fit: BoxFit.cover),
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

class _SummerSaleTile extends StatelessWidget {
  const _SummerSaleTile();

  @override
  Widget build(BuildContext context) => StreamBuilder<DateTime>(
    stream: Stream<DateTime>.periodic(
      const Duration(seconds: 1),
      (_) => DateTime.now(),
    ),
    initialData: DateTime.now(),
    builder: (context, snapshot) {
      final now = snapshot.data ?? DateTime.now();
      final remaining = DateTime(
        now.year,
        now.month,
        now.day + 1,
      ).difference(now);
      final timer = [
        remaining.inHours,
        remaining.inMinutes % 60,
        remaining.inSeconds % 60,
      ].map((value) => value.toString().padLeft(2, '0')).toList();
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xffdf202d), Color(0xffa90d1b)],
          ),
        ),
        padding: const EdgeInsets.all(6),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'SUMMER\nSALE',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'UP TO 45% OFF',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final value in timer)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        value,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
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
          placeholder: (context, url) =>
              const ColoredBox(color: Color(0xffeeeeee)),
          errorWidget: (context, url, error) => const ColoredBox(
            color: Color(0xffeeeeee),
            child: Center(
              child: Icon(Icons.image_outlined, color: Colors.grey),
            ),
          ),
        );
      },
    );
  }
}

class _ProductRail extends StatefulWidget {
  const _ProductRail({
    required this.title,
    required this.products,
    required this.handle,
    this.tabs = const [],
    this.alternateProducts = const [],
    this.alternateHandle,
  });
  final String title;
  final List<ProductSummary> products;
  final String handle;
  final List<String> tabs;
  final List<ProductSummary> alternateProducts;
  final String? alternateHandle;

  @override
  State<_ProductRail> createState() => _ProductRailState();
}

class _ProductRailState extends State<_ProductRail> {
  final ScrollController _scroll = ScrollController();
  int _selectedTab = 0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _move(int direction, double width) {
    if (!_scroll.hasClients) return;
    final target = (_scroll.offset + direction * (width + 10)).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    );
    _scroll.animateTo(
      target,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final products = _selectedTab == 1 && widget.alternateProducts.isNotEmpty
        ? widget.alternateProducts
        : widget.products;
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
                  widget.title,
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
                  pathParameters: {
                    'handle': _selectedTab == 1
                        ? widget.alternateHandle ?? widget.handle
                        : widget.handle,
                  },
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
        if (widget.tabs.isNotEmpty) ...[
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                for (var i = 0; i < widget.tabs.length; i++) ...[
                  if (i > 0) const SizedBox(width: 27),
                  InkWell(
                    onTap: () {
                      setState(() => _selectedTab = i);
                      if (_scroll.hasClients) _scroll.jumpTo(0);
                    },
                    child: Text(
                      widget.tabs[i],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        decoration: i == _selectedTab
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
          child: Stack(
            children: [
              ListView.separated(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                scrollDirection: Axis.horizontal,
                itemCount: products.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) => SizedBox(
                  width: cardWidth,
                  child: StorefrontProductCard(product: products[index]),
                ),
              ),
              if (products.length > 2)
                Positioned(
                  right: 14,
                  top: cardWidth * .6,
                  child: Material(
                    color: Colors.white,
                    elevation: 1,
                    child: IconButton(
                      tooltip: 'Next products',
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => _move(1, cardWidth),
                    ),
                  ),
                ),
            ],
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
                  const SizedBox(height: 8),
                  const Text(
                    'A Collection By FLEXWOLF',
                    style: TextStyle(color: Colors.white, fontSize: 13),
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
      height: MediaQuery.sizeOf(context).width,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const _HomeImage(
            url: 'https://flexwolf.co/cdn/shop/files/new_banner_21.065.2026_mobile.png?v=1781989756&width=900',
          ),
          const ColoredBox(color: Color(0x44000000)),
          Padding(
            padding: const EdgeInsets.fromLTRB(25, 0, 25, 25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'LOOK BETTER.\nTRAIN HARDER.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    height: 1.25,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 17),
                const Text(
                  'Premium athletic apparel engineered for comfort and performance.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(height: 8),
                const Text(
                  '\u2713 Sweat-Wicking\n\u2713 4-Way Stretch\n\u2713 Built for Training',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.6,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
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
    color: const Color(0xff202020),
    padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FooterRow('SHOP', [
          ('All Products', () => context.goNamed(AppRouteNames.shop)),
          (
            'New Arrivals',
            () => context.goNamed(
              AppRouteNames.collection,
              pathParameters: const {'handle': 'new-arrivals'},
            ),
          ),
          (
            'Tank Tops',
            () => context.goNamed(
              AppRouteNames.collection,
              pathParameters: const {'handle': 'gym-vest'},
            ),
          ),
        ]),
        _FooterRow('SUPPORT', [
          ('Contact Us', () => context.goNamed(AppRouteNames.support)),
          ('Returns', () => _openStorePage('/policies/refund-policy')),
          (
            'Shipping Policy',
            () => _openStorePage('/policies/shipping-policy'),
          ),
        ]),
        _FooterRow('CONNECT', [
          (
            'Instagram',
            () => _openUrl('https://www.instagram.com/flexwolf.co'),
          ),
          ('Facebook', () => _openUrl('https://www.facebook.com/flexwolf.co')),
          ('YouTube', () => _openUrl('https://youtube.com/c/flexwolf_apparel')),
        ]),
        _FooterRow('ABOUT US', [
          ('Our Story', () => _openStorePage('/pages/about-us')),
          ('Contact', () => context.goNamed(AppRouteNames.support)),
        ]),
        const SizedBox(height: 30),
        Image.asset(
          'assets/images/home_payment_methods.jpg',
          fit: BoxFit.fitWidth,
        ),
        const SizedBox(height: 24),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SocialBadge('facebook', 'https://www.facebook.com/flexwolf.co'),
            _SocialBadge('x', 'https://x.com/flexwolfusa'),
            _SocialBadge('instagram', 'https://www.instagram.com/flexwolf.co'),
            _SocialBadge('threads', 'https://threads.net/flexwolf.co'),
            _SocialBadge('pinterest', 'https://pinterest.com/flexwolfusa'),
            _SocialBadge('youtube', 'https://youtube.com/c/flexwolf_apparel'),
          ],
        ),
        const SizedBox(height: 9),
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SocialBadge('tiktok', 'https://www.tiktok.com/@flexwolfusa'),
            _SocialBadge(
              'linkedin',
              'https://www.linkedin.com/company/flexwolf',
            ),
            _SocialBadge(
              'snapchat',
              'https://www.snapchat.com/add/flexwolf.co',
            ),
          ],
        ),
        const SizedBox(height: 26),
        const Divider(color: Color(0xff5b5b5b)),
        const SizedBox(height: 10),
        const Text(
          '© 2026 | FLEXWOLF | All Rights Reserved. | Trust Like a Wolf.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 10),
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          children: [
            _LegalLink('Refund policy', '/policies/refund-policy'),
            _LegalLink('Privacy policy', '/policies/privacy-policy'),
            _LegalLink('Terms of service', '/policies/terms-of-service'),
            _LegalLink('Shipping policy', '/policies/shipping-policy'),
          ],
        ),
      ],
    ),
  );
}

class _FooterRow extends StatelessWidget {
  const _FooterRow(this.label, this.links);
  final String label;
  final List<(String, VoidCallback)> links;
  @override
  Widget build(BuildContext context) => ExpansionTile(
    tilePadding: EdgeInsets.zero,
    childrenPadding: const EdgeInsets.only(bottom: 10),
    collapsedShape: const Border(bottom: BorderSide(color: Color(0xff5b5b5b))),
    shape: const Border(bottom: BorderSide(color: Color(0xff5b5b5b))),
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
      for (final link in links)
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(
            link.$1,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          onTap: link.$2,
        ),
    ],
  );
}

class _SocialBadge extends StatelessWidget {
  const _SocialBadge(this.name, this.url);
  final String name;
  final String url;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 4),
    child: InkWell(
      onTap: () => _openUrl(url),
      customBorder: const CircleBorder(),
      child: ClipOval(
        child: Image.asset(
          'assets/images/home_social_$name.jpg',
          width: 36,
          height: 36,
          fit: BoxFit.cover,
        ),
      ),
    ),
  );
}

class _LegalLink extends StatelessWidget {
  const _LegalLink(this.label, this.path);
  final String label;
  final String path;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => _openStorePage(path),
    child: Text(
      label,
      style: const TextStyle(color: Colors.white54, fontSize: 10),
    ),
  );
}

Future<void> _openStorePage(String path) =>
    _openUrl('https://flexwolf.co$path');

Future<void> _openUrl(String url) async {
  final uri = Uri.parse(url);
  await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
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
