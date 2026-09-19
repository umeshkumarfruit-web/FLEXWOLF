import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/widgets/app_button.dart';
import 'package:flexwolf/core/widgets/app_empty_state.dart';
import 'package:flexwolf/core/widgets/app_error_state.dart';
import 'package:flexwolf/features/engagement/data/engagement_providers.dart';
import 'package:flexwolf/features/engagement/domain/engagement_models.dart';
import 'package:flexwolf/features/home/presentation/renderers/home_section_renderer_registry.dart';
import 'package:flexwolf/features/shop/domain/product.dart';
import 'package:flexwolf/integrations/analytics/analytics_boundary.dart';
import 'package:flexwolf/core/services/service_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RecentlyViewedRail extends ConsumerWidget {
  const RecentlyViewedRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(recentlyViewedProvider);
    return items.when(
      loading: () => const HomeRailSkeleton(title: 'Recently viewed'),
      error: (error, stack) => AppErrorState(
        error: mapUnknownException(error),
        onRetry: () => ref.invalidate(recentlyViewedProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return const AppEmptyState(
            title: 'Recently viewed',
            message: 'Products you view will appear here.',
            icon: Icons.history,
          );
        }
        return Semantics(
          label: 'Recently viewed products',
          explicitChildNodes: true,
          child: SizedBox(
            height: 312,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final product = items[index].product;
                if (product == null) {
                  return SizedBox(
                    width: 156,
                    child: AppEmptyState(
                      title: items[index].title,
                      message: 'Product unavailable.',
                      icon: Icons.inventory_2_outlined,
                    ),
                  );
                }
                return SizedBox(
                  width: 156,
                  child: HomeProductCard(
                    product: product,
                    onTap: () {
                      ref
                          .read(analyticsGatewayProvider)
                          .track(
                            const AnalyticsEvent(
                              name: AppAnalyticsEvents.recommendationClick,
                            ),
                          );
                      context.go('/shop/products/${product.handle}');
                    },
                  ),
                );
              },
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
              itemCount: items.length,
            ),
          ),
        );
      },
    );
  }
}

class RecommendationRail extends ConsumerWidget {
  const RecommendationRail({required this.request, super.key});

  final ProductRecommendationRequest request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(recommendationsProvider(request));
    return products.when(
      loading: () => const HomeRailSkeleton(title: 'Recommended products'),
      error: (error, stack) => AppErrorState(
        error: mapUnknownException(error),
        onRetry: () => ref.invalidate(recommendationsProvider(request)),
      ),
      data: (products) {
        if (products.isEmpty) {
          return const AppEmptyState(
            title: 'Recommendations unavailable',
            message:
                'Recommendations will appear when Shopify data is available.',
            icon: Icons.auto_awesome_outlined,
          );
        }
        return SizedBox(
          height: 312,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) => SizedBox(
              width: 156,
              child: HomeProductCard(
                product: products[index],
                onTap: () {
                  ref
                      .read(analyticsGatewayProvider)
                      .track(
                        AnalyticsEvent(
                          name: AppAnalyticsEvents.recommendationClick,
                          parameters: {'kind': request.kind.name},
                        ),
                      );
                  context.go('/shop/products/${products[index].handle}');
                },
              ),
            ),
            separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
            itemCount: products.length,
          ),
        );
      },
    );
  }
}

class EngagementAlertButton extends ConsumerStatefulWidget {
  const EngagementAlertButton({
    required this.product,
    required this.kind,
    this.email,
    super.key,
  });

  final ProductSummary product;
  final EngagementAlertKind kind;
  final String? email;

  @override
  ConsumerState<EngagementAlertButton> createState() =>
      _EngagementAlertButtonState();
}

class _EngagementAlertButtonState extends ConsumerState<EngagementAlertButton> {
  bool _busy = false;
  bool _registered = false;

  @override
  Widget build(BuildContext context) {
    final label = widget.kind == EngagementAlertKind.backInStock
        ? (_registered ? 'Remove Stock Alert' : 'Back In Stock')
        : (_registered ? 'Remove Price Alert' : 'Price Drop Alert');
    return AppButton.secondary(
      label: _busy ? 'Saving' : label,
      icon: widget.kind == EngagementAlertKind.backInStock
          ? Icons.notifications_outlined
          : Icons.trending_down,
      semanticLabel: label,
      onPressed: _busy ? null : _toggle,
    );
  }

  Future<void> _toggle() async {
    setState(() => _busy = true);
    final registration = EngagementAlertRegistration(
      kind: widget.kind,
      productId: widget.product.id,
      productHandle: widget.product.handle,
      email: widget.email,
      createdAt: DateTime.now().toUtc(),
    );
    try {
      final repo = ref.read(engagementRepositoryProvider);
      if (_registered) {
        await repo.removeAlert(registration);
      } else {
        await repo.registerAlert(registration);
        await ref
            .read(analyticsGatewayProvider)
            .track(
              AnalyticsEvent(
                name: widget.kind == EngagementAlertKind.backInStock
                    ? AppAnalyticsEvents.backInStockRegistration
                    : AppAnalyticsEvents.priceDropRegistration,
                parameters: {'productId': widget.product.id},
              ),
            );
      }
      if (mounted) setState(() => _registered = !_registered);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
