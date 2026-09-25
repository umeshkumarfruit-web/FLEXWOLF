import 'package:flexwolf/app/router/route_names.dart';
import 'package:flexwolf/core/widgets/app_remote_image.dart';
import 'package:flexwolf/features/reviews/data/review_providers.dart';
import 'package:flexwolf/features/reviews/presentation/product_reviews_section.dart';
import 'package:flexwolf/features/shop/data/shop_providers.dart';
import 'package:flexwolf/features/shop/domain/cart.dart';
import 'package:flexwolf/features/shop/domain/product.dart';
import 'package:flexwolf/features/shop/domain/product_media.dart';
import 'package:flexwolf/features/shop/domain/product_variant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The product builder shown between the category tiles and product rails.
class HomeFeatureProduct extends ConsumerStatefulWidget {
  const HomeFeatureProduct({required this.product, super.key});

  final ProductSummary product;

  @override
  ConsumerState<HomeFeatureProduct> createState() => _HomeFeatureProductState();
}

class _HomeFeatureProductState extends ConsumerState<HomeFeatureProduct> {
  final PageController _gallery = PageController();
  int _page = 0;
  int _pack = 3;
  String? _size;
  String? _color;
  bool _customPack = true;
  bool _busy = false;
  List<String?> _bundleColors = List<String?>.filled(3, null);

  @override
  void dispose() {
    _gallery.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final colors = product.variants
        .map((variant) => variant.color)
        .whereType<String>()
        .toSet()
        .toList();
    final sizes = product.variants
        .map((variant) => variant.size)
        .whereType<String>()
        .toSet()
        .toList();
    _color ??= colors.firstOrNull;
    final selected = _variantFor(_color, _size) ?? product.variants.firstOrNull;
    final previewImages = <String>[];
    final previewColors = <String>{};
    for (final variant in product.variants) {
      if (variant.color != null &&
          variant.image != null &&
          previewColors.add(variant.color!)) {
        previewImages.add(variant.image!.url);
      }
      if (previewImages.length == 3) break;
    }
    final images = <ProductImage>[
      if (selected?.image != null) selected!.image!,
      ...product.images,
      if (product.images.isEmpty && product.featuredImage != null)
        product.featuredImage!,
    ];
    final seen = <String>{};
    final galleryImages = images.where((image) => seen.add(image.url)).toList();
    final key = ReviewProductKey(
      productId: product.id,
      productHandle: product.handle,
    );
    final rating = ref.watch(reviewSummaryProvider(key));
    final canAdd =
        !_busy &&
        _size != null &&
        (_pack == 1 ||
            !_customPack ||
            _bundleColors.every((color) => color != null)) &&
        (_pack == 1 || !_customPack
            ? _variantFor(_color, _size)?.availableForSale == true
            : _bundleColors.every(
                (color) => _variantFor(color, _size)?.availableForSale == true,
              ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: _openProduct,
          icon: const Icon(Icons.chevron_left, size: 16),
          label: const Text('Shop'),
          style: TextButton.styleFrom(foregroundColor: Colors.black),
        ),
        AspectRatio(
          aspectRatio: .77,
          child: Stack(
            fit: StackFit.expand,
            children: [
              PageView.builder(
                controller: _gallery,
                itemCount: galleryImages.length,
                onPageChanged: (page) => setState(() => _page = page),
                itemBuilder: (context, index) => AppRemoteImage(
                  imageUrl: galleryImages[index].url,
                  semanticLabel: galleryImages[index].altText ?? product.title,
                ),
              ),
              if (galleryImages.length > 1) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: _GalleryArrow(
                    icon: Icons.chevron_left,
                    onPressed: () => _moveGallery(-1, galleryImages.length),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: _GalleryArrow(
                    icon: Icons.chevron_right,
                    onPressed: () => _moveGallery(1, galleryImages.length),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (galleryImages.length > 1)
          SizedBox(
            height: 29,
            child: Center(
              child: ListView.separated(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                itemCount: galleryImages.length,
                separatorBuilder: (_, _) => const SizedBox(width: 5),
                itemBuilder: (context, index) => InkWell(
                  onTap: () => _gallery.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOut,
                  ),
                  child: CircleAvatar(
                    radius: 3,
                    backgroundColor: _page == index
                        ? Colors.black
                        : const Color(0xffc8c8c8),
                  ),
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: _openProduct,
                child: Text(
                  product.title,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              rating.when(
                data: (summary) => InkWell(
                  onTap: _openProduct,
                  child: Text(
                    summary.totalReviews == null || summary.totalReviews == 0
                        ? 'Reviews'
                        : '★★★★★  (${summary.totalReviews})  Reviews',
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
                loading: () => const SizedBox(height: 17),
                error: (_, _) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 14),
              Text(
                'Color: ${_customPack && _pack > 1 ? 'Mix & Match' : _color ?? 'Choose a color'}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _PackModeCard(
                    title: 'Customize',
                    subtitle: 'Mix colors',
                    images: previewImages,
                    selected: _customPack,
                    onTap: () => setState(() => _customPack = true),
                  ),
                  const SizedBox(width: 8),
                  _PackModeCard(
                    title: 'Custom Pack',
                    subtitle: _color ?? 'One color',
                    images: [if (selected?.image != null) selected!.image!.url],
                    selected: !_customPack,
                    onTap: () => setState(() => _customPack = false),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (!_customPack || _pack == 1)
                SizedBox(
                  height: 42,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: colors.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 7),
                    itemBuilder: (context, index) => ChoiceChip(
                      label: Text(colors[index]),
                      selected: _color == colors[index],
                      onSelected: (_) => setState(() => _color = colors[index]),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              if (selected != null)
                Text(
                  '${_money(selected.price.currencyCode, selected.price.amount.value)}  |  Quantity: $_pack',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final count in const [10, 5, 3, 1])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: OutlinedButton(
                          onPressed: () => setState(() {
                            _pack = count;
                            _bundleColors = List<String?>.filled(count, null);
                          }),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 2,
                              vertical: 10,
                            ),
                            foregroundColor: Colors.black,
                            side: BorderSide(
                              color: _pack == count
                                  ? Colors.black
                                  : Colors.grey.shade300,
                            ),
                            shape: const RoundedRectangleBorder(),
                          ),
                          child: Text(
                            count == 1 ? 'Singles' : '$count-Pack',
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Size: Choose a size.',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (product.handle == 'flex-arm-tank')
                    TextButton(
                      onPressed: _showSizeChart,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.zero,
                      ),
                      child: const Text(
                        'Sizing Chart',
                        style: TextStyle(decoration: TextDecoration.underline),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: [
                  for (final size in sizes)
                    OutlinedButton(
                      onPressed: () => setState(() => _size = size),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: BorderSide(
                          color: _size == size
                              ? Colors.black
                              : Colors.grey.shade300,
                        ),
                        shape: const RoundedRectangleBorder(),
                      ),
                      child: Text(size),
                    ),
                ],
              ),
              if (_customPack && _pack > 1) ...[
                const SizedBox(height: 22),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Your Bundle | click to customize',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${_bundleColors.whereType<String>().length} / $_pack',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 107,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _pack,
                    separatorBuilder: (_, _) => const SizedBox(width: 7),
                    itemBuilder: (context, index) => InkWell(
                      onTap: () => _chooseBundleColor(index, colors),
                      child: Container(
                        width: 80,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Center(
                          child: Text(
                            _bundleColors[index] ?? '+',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: _bundleColors[index] == null ? 26 : 11,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: canAdd ? _addToBag : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.black,
                    disabledBackgroundColor: const Color(0xffb6b6b6),
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(
                    _busy
                        ? 'ADDING TO BAG...'
                        : canAdd
                        ? 'ADD TO BAG'
                        : 'SELECT YOUR OPTIONS',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _FeatureAccordion(
                label: 'Product Details',
                child: Text(
                  product.description ?? 'Product details are unavailable.',
                ),
              ),
              _FeatureAccordion(
                label: 'Reviews',
                child: ProductReviewsSection(product: product),
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(Icons.verified_user_outlined, size: 22),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '60-Day Guarantee\nEasy Returns & Exchanges',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                  Icon(Icons.local_shipping_outlined, size: 22),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Ships Same Day\nFast dispatch on all orders',
                      style: TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  ProductVariant? _variantFor(String? color, String? size) {
    if (color == null || size == null) return null;
    for (final variant in widget.product.variants) {
      if (variant.color == color && variant.size == size) return variant;
    }
    return null;
  }

  void _moveGallery(int delta, int length) {
    _gallery.animateToPage(
      (_page + delta).clamp(0, length - 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _openProduct() => context.goNamed(
    AppRouteNames.product,
    pathParameters: {'handle': widget.product.handle},
  );

  Future<void> _chooseBundleColor(int index, List<String> colors) async {
    final color = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('CHOOSE A COLOR')),
            for (final color in colors)
              ListTile(
                title: Text(color),
                enabled:
                    _size == null ||
                    _variantFor(color, _size)?.availableForSale == true,
                onTap: () => Navigator.pop(sheetContext, color),
              ),
          ],
        ),
      ),
    );
    if (color != null && mounted) setState(() => _bundleColors[index] = color);
  }

  void _showSizeChart() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Flex Arm Tank — Sizing Chart',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Table(
                border: TableBorder.all(color: const Color(0xffdddddd)),
                children: [
                  for (final row in const [
                    ['Size', 'Chest', 'Length'],
                    ['S', '35 Inch', '28.5 Inch'],
                    ['M', '37 Inch', '29 Inch'],
                    ['L', '39 Inch', '30 Inch'],
                    ['XL', '43 Inch', '30.5 Inch'],
                    ['2XL', '46 Inch', '31 Inch'],
                    ['3XL', '49 Inch', '31.5 Inch'],
                  ])
                    TableRow(
                      children: [
                        for (final cell in row)
                          Padding(
                            padding: const EdgeInsets.all(9),
                            child: Text(
                              cell,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addToBag() async {
    if (_size == null) return;
    final chosenColors = _customPack && _pack > 1
        ? _bundleColors.whereType<String>().toList()
        : List<String>.filled(_pack, _color!);
    final quantities = <String, int>{};
    final variants = <String, ProductVariant>{};
    for (final color in chosenColors) {
      final variant = _variantFor(color, _size);
      if (variant == null || !variant.availableForSale) return;
      variants[variant.id] = variant;
      quantities.update(variant.id, (count) => count + 1, ifAbsent: () => 1);
    }
    setState(() => _busy = true);
    try {
      await ref.read(cartControllerProvider).addLines([
        for (final entry in quantities.entries)
          CartLineInput(
            merchandiseId: entry.key,
            quantity: entry.value,
            title: widget.product.title,
            variantTitle: variants[entry.key]!.title,
            price: variants[entry.key]!.price,
            imageUrl:
                variants[entry.key]!.image?.url ??
                widget.product.featuredImage?.url,
          ),
      ]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_pack ${widget.product.title} added to bag'),
            action: SnackBarAction(
              label: 'VIEW BAG',
              onPressed: () => context.push('/cart'),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not add this pack. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _GalleryArrow extends StatelessWidget {
  const _GalleryArrow({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10),
    child: Material(
      color: Colors.white,
      child: IconButton(icon: Icon(icon, size: 18), onPressed: onPressed),
    ),
  );
}

class _PackModeCard extends StatelessWidget {
  const _PackModeCard({
    required this.title,
    required this.subtitle,
    required this.images,
    required this.selected,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final List<String> images;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      onTap: onTap,
      child: Container(
        height: 112,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: const Color(0xfff1f1f1),
          border: Border.all(
            color: selected ? Colors.black : Colors.grey.shade300,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: images.isEmpty
                  ? const Icon(Icons.checkroom_outlined, color: Colors.grey)
                  : Row(
                      children: [
                        for (final image in images)
                          Expanded(
                            child: AppRemoteImage(
                              imageUrl: image,
                              semanticLabel: title,
                            ),
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    ),
  );
}

class _FeatureAccordion extends StatelessWidget {
  const _FeatureAccordion({required this.label, required this.child});
  final String label;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xffe5e5e5)),
    ),
    child: ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 14),
      title: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      children: [Align(alignment: Alignment.centerLeft, child: child)],
    ),
  );
}

String _money(String currency, String amount) =>
    '${currency == 'INR' ? 'Rs.' : currency} $amount';
