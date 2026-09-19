import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flexwolf/core/widgets/app_badge.dart';
import 'package:flexwolf/core/widgets/app_button.dart';
import 'package:flexwolf/core/widgets/app_empty_state.dart';
import 'package:flexwolf/core/widgets/app_loading_indicator.dart';
import 'package:flexwolf/core/widgets/app_price.dart';
import 'package:flexwolf/core/widgets/app_product_card_shell.dart';
import 'package:flexwolf/core/widgets/app_remote_image.dart';
import 'package:flexwolf/core/widgets/app_section_heading.dart';
import 'package:flexwolf/features/engagement/domain/engagement_models.dart';
import 'package:flexwolf/features/engagement/data/engagement_providers.dart';
import 'package:flexwolf/features/engagement/presentation/engagement_widgets.dart';
import 'package:flexwolf/features/home/data/home_content_providers.dart';
import 'package:flexwolf/features/home/domain/home_config.dart';
import 'package:flexwolf/features/home/domain/home_content_repository.dart';
import 'package:flexwolf/features/home/domain/home_section_registry.dart';
import 'package:flexwolf/features/home/presentation/home_action_dispatcher.dart';
import 'package:flexwolf/features/shop/domain/product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef HomeSectionWidgetBuilder = Widget Function(
  HomeSectionRenderContext context,
);

class HomeSectionRenderContext {
  const HomeSectionRenderContext({
    required this.section,
    required this.actionDispatcher,
    required this.nowUtc,
  });

  final HomeSectionConfig section;
  final HomeActionDispatcher actionDispatcher;
  final DateTime nowUtc;
}

abstract final class HomeSectionRendererRegistry {
  static final Map<HomeSectionType, HomeSectionWidgetBuilder> _builders = {
    HomeSectionType.mainHeroBanner: (context) =>
        HomeHeroBanner(context: context),
    HomeSectionType.newDrop: _productRail,
    HomeSectionType.newArrivals: _collectionRail,
    HomeSectionType.bestSellers: _collectionRail,
    HomeSectionType.trending: _collectionRail,
    HomeSectionType.sale: _collectionRail,
    HomeSectionType.collection365: _collectionFeature,
    HomeSectionType.flexArmCollection: _collectionFeature,
    HomeSectionType.shorts: _collectionFeature,
    HomeSectionType.sweats: _collectionFeature,
    HomeSectionType.appExclusives: _productRail,
    HomeSectionType.recommendedForYou: (context) =>
        EngagementRecommendationSection(context: context),
    HomeSectionType.recentlyViewed: (context) =>
        EngagementRecentlyViewedSection(context: context),
    HomeSectionType.completeTheLook: (context) => HomeProductRail(
      context: context,
      layout: HomeProductRailLayout.completeTheLook,
    ),
    HomeSectionType.creatorPicks: _editorialRail,
    HomeSectionType.athletePicks: _editorialRail,
    HomeSectionType.shoppableVideos: (context) => HomeMediaSection(
      context: context,
      dependencyLabel: 'CLIENT DEPENDENCY: approved shoppable video provider/content required.',
      icon: Icons.play_circle_outline,
    ),
    HomeSectionType.customerUgc: (context) => HomeMediaSection(
      context: context,
      dependencyLabel:
          'CLIENT DEPENDENCY: approved moderated UGC content required.',
      icon: Icons.photo_library_outlined,
    ),
    HomeSectionType.backInStock: (context) => EngagementRecommendationSection(
      context: context,
      kind: RecommendationKind.trendingProducts,
    ),
    HomeSectionType.limitedDrop: _collectionRail,
    HomeSectionType.countdown: (context) =>
        HomeCountdownSection(context: context),
    HomeSectionType.memberExclusive: (context) => HomeDependencySection(
      context: context,
      dependencyLabel:
          'LATER CONTRACT PHASE: FLEXWOLF membership is not live yet.',
    ),
  };

  static bool hasRenderer(HomeSectionType type) => _builders.containsKey(type);

  static Widget render(HomeSectionRenderContext context) {
    final builder = _builders[context.section.type];
    if (builder == null) {
      return const SizedBox.shrink();
    }
    return KeyedSubtree(
      key: ValueKey<String>('home-section-${context.section.id}'),
      child: Material(color: Colors.transparent, child: builder(context)),
    );
  }

  static Iterable<HomeSectionType> get registeredTypes => _builders.keys;

  static Widget _productRail(HomeSectionRenderContext context) {
    return HomeProductRail(context: context);
  }

  static Widget _collectionRail(HomeSectionRenderContext context) {
    return HomeProductRail(context: context, preferCollectionProducts: true);
  }

  static Widget _collectionFeature(HomeSectionRenderContext context) {
    return HomeCollectionFeatureSection(context: context);
  }

  static Widget _editorialRail(HomeSectionRenderContext context) {
    return HomeEditorialProductSection(context: context);
  }
}

class EngagementRecentlyViewedSection extends ConsumerWidget {
  const EngagementRecentlyViewedSection({required this.context, super.key});

  final HomeSectionRenderContext context;

  @override
  Widget build(BuildContext buildContext, WidgetRef ref) {
    return ref.watch(recentlyViewedProvider).when(
      loading: () => HomeSectionFrame(
        section: context.section,
        actionDispatcher: context.actionDispatcher,
        child: const HomeRailSkeleton(title: 'Recently viewed'),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) => items.isEmpty
          ? const SizedBox.shrink()
          : HomeSectionFrame(
              section: context.section,
              actionDispatcher: context.actionDispatcher,
              child: const RecentlyViewedRail(),
            ),
    );
  }
}

class EngagementRecommendationSection extends StatelessWidget {
  const EngagementRecommendationSection({
    required this.context,
    this.kind = RecommendationKind.recommendedProducts,
    super.key,
  });

  final HomeSectionRenderContext context;
  final RecommendationKind kind;

  @override
  Widget build(BuildContext buildContext) {
    return HomeSectionFrame(
      section: context.section,
      actionDispatcher: context.actionDispatcher,
      child: RecommendationRail(
        request: ProductRecommendationRequest(kind: kind),
      ),
    );
  }
}

class HomeHeroBanner extends StatelessWidget {
  const HomeHeroBanner({required this.context, super.key});

  final HomeSectionRenderContext context;

  @override
  Widget build(BuildContext buildContext) {
    final section = context.section;
    final media = section.content.media;
    final actionEnabled = context.actionDispatcher.canDispatch(
      section.destination,
    );

    return Semantics(
      label:
          section.accessibility.semanticLabel ??
          section.content.title ??
          section.analyticsName,
      button: actionEnabled,
      child: InkWell(
        onTap: actionEnabled
            ? () => context.actionDispatcher.dispatch(
                buildContext,
                section.destination,
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          child: ClipRect(
            child: AspectRatio(
              aspectRatio: media?.aspectRatio ?? 0.78,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (media != null)
                    AppRemoteImage(
                      imageUrl: _bestImageUrl(buildContext, media),
                      semanticLabel:
                          section.accessibility.imageAltText ?? media.altText,
                      aspectRatio: media.aspectRatio ?? 0.78,
                    )
                  else
                    const AppSkeletonLoader(height: 420),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[Color(0x08000000), Color(0xB8000000)],
                        stops: <double>[0.35, 1],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (section.content.subtitle != null) ...[
                          Text(
                            section.content.subtitle!.toUpperCase(),
                            style: Theme.of(buildContext).textTheme.labelMedium
                                ?.copyWith(
                                  color: AppColors.white,
                                  letterSpacing: 2,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        if (section.content.title != null)
                          Text(
                            section.content.title!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(buildContext).textTheme.displaySmall
                                ?.copyWith(
                                  color: AppColors.surface,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2.5,
                                ),
                          ),
                        if (section.content.body != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            section.content.body!,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(buildContext).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.neutral100),
                          ),
                        ],
                        if (section.content.ctaText != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          Semantics(
                            label: section.accessibility.ctaLabel,
                            button: true,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.white,
                                side: const BorderSide(
                                  color: AppColors.white,
                                  width: AppBorders.strong,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                ),
                              ),
                              onPressed: actionEnabled
                                  ? () => context.actionDispatcher.dispatch(
                                      buildContext,
                                      section.destination,
                                    )
                                  : null,
                              child: Text(section.content.ctaText!),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeProductRail extends ConsumerStatefulWidget {
  const HomeProductRail({
    required this.context,
    this.preferCollectionProducts = false,
    this.dependencyLabel,
    this.layout = HomeProductRailLayout.standard,
    super.key,
  });

  final HomeSectionRenderContext context;
  final bool preferCollectionProducts;
  final String? dependencyLabel;
  final HomeProductRailLayout layout;

  @override
  ConsumerState<HomeProductRail> createState() => _HomeProductRailState();
}

class _HomeProductRailState extends ConsumerState<HomeProductRail> {
  late Future<List<ProductSummary>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = _resolveProducts(ref.read(homeCommerceResolverProvider));
  }

  @override
  void didUpdateWidget(covariant HomeProductRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.context.section.id != widget.context.section.id) {
      _productsFuture = _resolveProducts(
        ref.read(homeCommerceResolverProvider),
      );
    }
  }

  @override
  Widget build(BuildContext buildContext) {
    return FutureBuilder<List<ProductSummary>>(
      future: _productsFuture,
      builder: (buildContext, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return HomeRailSkeleton(
            title:
                widget.context.section.content.title ??
                widget.context.section.analyticsName,
          );
        }
        if (snapshot.hasError) {
          return HomeSectionFrame(
            section: widget.context.section,
            actionDispatcher: widget.context.actionDispatcher,
            child: AppEmptyState(
              title: 'Products could not load',
              message:
                  'This section is still available to retry from Home refresh.',
              icon: Icons.wifi_off_outlined,
            ),
          );
        }
        final products = snapshot.data ?? const <ProductSummary>[];
        if (products.isEmpty) {
          return const SizedBox.shrink();
        }
        return HomeSectionFrame(
          section: widget.context.section,
          actionDispatcher: widget.context.actionDispatcher,
          child: SizedBox(
            height: widget.layout == HomeProductRailLayout.completeTheLook
                ? 320
                : 312,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              itemCount: products.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemBuilder: (buildContext, index) {
                return SizedBox(
                  width: widget.layout == HomeProductRailLayout.completeTheLook
                      ? 170
                      : 156,
                  child: HomeProductCard(
                    product: products[index],
                    onTap: () => widget.context.actionDispatcher.dispatch(
                      buildContext,
                      HomeDestination(
                        type: HomeDestinationType.product,
                        value: products[index].handle,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<List<ProductSummary>> _resolveProducts(
    HomeCommerceResolver resolver,
  ) async {
    final products = <ProductSummary>[];
    final seenIds = <String>{};

    if (widget.preferCollectionProducts ||
        widget.context.section.productReferences.isEmpty) {
      final collectionProducts = await Future.wait(
        widget.context.section.collectionReferences.map(
          resolver.resolveCollection,
        ),
      );
      for (final collection in collectionProducts.whereType()) {
        for (final product
            in collection.products?.items ?? const <ProductSummary>[]) {
          if (seenIds.add(product.id)) {
            products.add(product);
          }
        }
      }
    }

    final directProducts = await Future.wait(
      widget.context.section.productReferences.map(resolver.resolveProduct),
    );
    for (final product in directProducts.whereType()) {
      if (seenIds.add(product.id)) {
        products.add(product);
      }
    }
    return products;
  }
}

class HomeProductCard extends StatelessWidget {
  const HomeProductCard({required this.product, this.onTap, super.key});

  final ProductSummary product;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final variant = product.variants.isEmpty ? null : product.variants.first;
    final image = product.featuredImage ?? variant?.image;
    final colorCount = _colorCount(product);
    final subtitle = colorCount == 0 ? null : '$colorCount colors';
    return AppProductCardShell(
      title: product.title,
      subtitle: subtitle,
      semanticLabel:
          '${product.title}${product.availableForSale ? '' : ', unavailable'}',
      onTap: onTap,
      badge: product.availableForSale
          ? null
          : const AppBadge(label: 'SOLD OUT'),
      image: image == null
          ? const AppSkeletonLoader()
          : AppRemoteImage(
              imageUrl: image.url,
              semanticLabel: image.altText ?? product.title,
              aspectRatio: AppAspectRatios.productCard,
            ),
      price: variant == null
          ? const Text('Price unavailable')
          : AppPrice(
              price: _moneyLabel(variant.price),
              compareAtPrice: variant.compareAtPrice == null
                  ? null
                  : _moneyLabel(variant.compareAtPrice!),
            ),
    );
  }

  int _colorCount(ProductSummary product) {
    for (final option in product.options) {
      if (option.name.toLowerCase() == 'color') {
        return option.values.length;
      }
    }
    return product.variants
        .map((variant) => variant.color)
        .whereType<String>()
        .toSet()
        .length;
  }
}

class HomeCollectionFeatureSection extends StatelessWidget {
  const HomeCollectionFeatureSection({required this.context, super.key});

  final HomeSectionRenderContext context;

  @override
  Widget build(BuildContext buildContext) {
    final section = context.section;
    return HomeSectionFrame(
      section: section,
      actionDispatcher: context.actionDispatcher,
      child: InkWell(
        onTap: context.actionDispatcher.canDispatch(section.destination)
            ? () => context.actionDispatcher.dispatch(
                buildContext,
                section.destination,
              )
            : null,
        child: AspectRatio(
          aspectRatio: 4 / 3,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (section.content.media != null)
                AppRemoteImage(
                  imageUrl: _bestImageUrl(buildContext, section.content.media!),
                  semanticLabel: section.content.media!.altText,
                  aspectRatio: 4 / 3,
                )
              else
                const ColoredBox(color: AppColors.inverseBackground),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[Colors.transparent, Color(0xB8000000)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'COLLECTION',
                      style: Theme.of(buildContext).textTheme.labelMedium
                          ?.copyWith(color: AppColors.white),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      section.content.title ?? section.analyticsName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(buildContext).textTheme.headlineSmall
                          ?.copyWith(color: AppColors.surface),
                    ),
                    if (section.content.subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        section.content.subtitle!,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(buildContext).textTheme.bodyMedium
                            ?.copyWith(color: AppColors.neutral100),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Icon(
                        Icons.arrow_forward,
                        color: AppColors.surface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeEditorialProductSection extends StatelessWidget {
  const HomeEditorialProductSection({required this.context, super.key});

  final HomeSectionRenderContext context;

  @override
  Widget build(BuildContext buildContext) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionFrame(
          section: context.section,
          actionDispatcher: context.actionDispatcher,
          child: Text(
            context.section.content.body ?? 'Approved editorial content required before production display.',
            style: Theme.of(buildContext).textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ),
        HomeProductRail(
          context: context,
          dependencyLabel: 'CLIENT DEPENDENCY: approved creator/athlete content and Shopify picks required.',
        ),
      ],
    );
  }
}

class HomeMediaSection extends StatelessWidget {
  const HomeMediaSection({
    required this.context,
    required this.dependencyLabel,
    required this.icon,
    super.key,
  });

  final HomeSectionRenderContext context;
  final String dependencyLabel;
  final IconData icon;

  @override
  Widget build(BuildContext buildContext) {
    final media = context.section.content.media;
    if (media == null) return const SizedBox.shrink();
    return HomeSectionFrame(
      section: context.section,
      actionDispatcher: context.actionDispatcher,
      child: Semantics(
        label:
            context.section.accessibility.semanticLabel ??
            context.section.content.title,
        child: Container(
          constraints: const BoxConstraints(minHeight: 164),
          decoration: BoxDecoration(
            color: AppColors.neutral100,
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(color: AppColors.border),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: AppRemoteImage(
                  imageUrl: _bestImageUrl(buildContext, media),
                  semanticLabel: media.altText,
                  aspectRatio: media.aspectRatio ?? AppAspectRatios.banner,
                ),
              ),
              Icon(icon, size: AppIconSizes.lg, color: AppColors.textPrimary),
              Positioned(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.md,
                child: Text(
                  context.section.content.body ?? dependencyLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(buildContext).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeCountdownSection extends StatefulWidget {
  const HomeCountdownSection({required this.context, super.key});

  final HomeSectionRenderContext context;

  @override
  State<HomeCountdownSection> createState() => _HomeCountdownSectionState();
}

class _HomeCountdownSectionState extends State<HomeCountdownSection>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext buildContext) {
    final end = widget.context.section.schedule.endsAt;
    if (end == null) {
      return HomeDependencySection(
        context: widget.context,
        dependencyLabel:
            'CLIENT DEPENDENCY: countdown endsAt must be configured.',
      );
    }
    final remaining = end.difference(DateTime.now().toUtc());
    if (remaining <= Duration.zero) {
      return const SizedBox.shrink();
    }
    return StreamBuilder<int>(
      stream: Stream<int>.periodic(const Duration(minutes: 1), (tick) => tick),
      builder: (buildContext, snapshot) {
        final currentRemaining = end.difference(DateTime.now().toUtc());
        if (currentRemaining <= Duration.zero) {
          return const SizedBox.shrink();
        }
        return HomeSectionFrame(
          section: widget.context.section,
          actionDispatcher: widget.context.actionDispatcher,
          child: Semantics(
            label:
                '${widget.context.section.content.title ?? 'Countdown'}: ${_remainingLabel(currentRemaining)} remaining',
            liveRegion: true,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.textPrimary, width: 1.5),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: AppIconSizes.lg),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      _remainingLabel(currentRemaining),
                      style: Theme.of(buildContext).textTheme.headlineSmall,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class HomeDependencySection extends StatelessWidget {
  const HomeDependencySection({
    required this.context,
    required this.dependencyLabel,
    super.key,
  });

  final HomeSectionRenderContext context;
  final String dependencyLabel;

  @override
  Widget build(BuildContext buildContext) {
    return const SizedBox.shrink();
  }
}

class HomeSectionFrame extends StatelessWidget {
  const HomeSectionFrame({
    required this.section,
    required this.actionDispatcher,
    required this.child,
    super.key,
  });

  final HomeSectionConfig section;
  final HomeActionDispatcher actionDispatcher;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final canDispatch = actionDispatcher.canDispatch(section.destination);
    return Semantics(
      container: true,
      label:
          section.accessibility.semanticLabel ??
          section.content.title ??
          section.analyticsName,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _HomeHeading(
                    title: section.content.title ?? section.analyticsName,
                    subtitle: section.content.subtitle,
                  ),
                ),
                if (canDispatch && section.content.ctaText != null)
                  AppButton.text(
                    label: section.content.ctaText!,
                    semanticLabel: section.accessibility.ctaLabel,
                    icon: Icons.arrow_forward,
                    onPressed: () =>
                        actionDispatcher.dispatch(context, section.destination),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            child,
          ],
        ),
      ),
    );
  }
}

class HomeRailSkeleton extends StatelessWidget {
  const HomeRailSkeleton({required this.title, super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionHeading(title: title),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 258,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, _) => const SizedBox(
                width: 156,
                child: Column(
                  children: [
                    AppSkeletonLoader(height: 204),
                    SizedBox(height: AppSpacing.sm),
                    AppSkeletonLoader(height: 16),
                  ],
                ),
              ),
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemCount: 3,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeHeading extends StatelessWidget {
  const _HomeHeading({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionHeading(title: title),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            subtitle!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}

enum HomeProductRailLayout { standard, completeTheLook }

String _bestImageUrl(BuildContext context, HomeMediaReference media) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < 600 && media.mobileUrl != null) {
    return media.mobileUrl!;
  }
  return media.url;
}

String _moneyLabel(dynamic money) {
  return '${money.currencyCode} ${money.amount}';
}

String _remainingLabel(Duration duration) {
  final safe = duration.isNegative ? Duration.zero : duration;
  final days = safe.inDays;
  final hours = safe.inHours.remainder(24);
  final minutes = safe.inMinutes.remainder(60);
  if (days > 0) {
    return '${days}d ${hours}h ${minutes}m';
  }
  if (hours > 0) {
    return '${hours}h ${minutes}m';
  }
  return '${minutes}m';
}
