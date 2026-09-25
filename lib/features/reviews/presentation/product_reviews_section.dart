import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/services/service_registry.dart';
import 'package:flexwolf/core/widgets/app_button.dart';
import 'package:flexwolf/core/widgets/app_empty_state.dart';
import 'package:flexwolf/core/widgets/app_error_state.dart';
import 'package:flexwolf/core/widgets/app_loading_indicator.dart';
import 'package:flexwolf/core/widgets/app_remote_image.dart';
import 'package:flexwolf/features/reviews/data/review_providers.dart';
import 'package:flexwolf/features/reviews/domain/product_reviews.dart';
import 'package:flexwolf/features/reviews/presentation/loox_in_app_review_screen.dart';
import 'package:flexwolf/features/shop/domain/pagination.dart';
import 'package:flexwolf/features/shop/domain/product.dart';
import 'package:flexwolf/integrations/analytics/analytics_boundary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductReviewsSection extends ConsumerStatefulWidget {
  const ProductReviewsSection({required this.product, super.key});

  final ProductSummary product;

  @override
  ConsumerState<ProductReviewsSection> createState() =>
      _ProductReviewsSectionState();
}

class _ProductReviewsSectionState extends ConsumerState<ProductReviewsSection>
    with WidgetsBindingObserver {
  static const _pageSize = 5;
  ReviewSort _sort = ReviewSort.latest;
  var _expanded = false;
  var _first = _pageSize;
  var _trackedViewed = false;

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
    if (state == AppLifecycleState.resumed) {
      _refreshReviews();
    }
  }

  @override
  Widget build(BuildContext context) {
    final key = ReviewProductKey(
      productId: widget.product.id,
      productHandle: widget.product.handle,
    );
    final summary = ref.watch(reviewSummaryProvider(key));
    final query = ReviewQuery(
      productId: widget.product.id,
      productHandle: widget.product.handle,
      pagination: PaginationRequest(first: _first),
      sort: _sort,
    );
    final reviews = _expanded ? ref.watch(reviewListProvider(query)) : null;

    return Semantics(
      container: true,
      label: 'Product reviews',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reviews', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          summary.when(
            loading: () => const _ReviewSummarySkeleton(),
            error: (error, stackTrace) => AppRetryState(
              title: 'Reviews are unavailable',
              message: _message(error),
              onRetry: () => ref.invalidate(reviewSummaryProvider(key)),
            ),
            data: (data) => data.hasData
                ? _ReviewSummaryView(summary: data)
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppButton.secondary(
                label: _expanded ? 'Hide Reviews' : 'View All Reviews',
                icon: _expanded
                    ? Icons.expand_less
                    : Icons.rate_review_outlined,
                semanticLabel: _expanded
                    ? 'Hide product reviews'
                    : 'View all product reviews',
                onPressed: () {
                  setState(() => _expanded = !_expanded);
                  if (!_trackedViewed) {
                    _trackedViewed = true;
                    _track(AppAnalyticsEvents.reviewOpened);
                  }
                },
              ),
              AppButton.secondary(
                label: 'Write Review',
                icon: Icons.edit_outlined,
                semanticLabel: 'Write a review for ${widget.product.title}',
                onPressed: _openReviewForm,
              ),
            ],
          ),
          if (_expanded) ...[
            const SizedBox(height: AppSpacing.md),
            _ReviewSortControl(
              value: _sort,
              onChanged: (value) {
                setState(() {
                  _sort = value;
                  _first = _pageSize;
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            reviews!.when(
              loading: () => const _ReviewListSkeleton(),
              error: (error, stackTrace) => AppRetryState(
                title: 'Reviews could not be loaded',
                message: _message(error),
                onRetry: () => ref.invalidate(reviewListProvider(query)),
              ),
              data: (data) {
                if (data.items.isEmpty) {
                  return const AppEmptyState(
                    title: 'No reviews yet',
                    message: 'Be the first to review this product.',
                    icon: Icons.rate_review_outlined,
                  );
                }
                return Column(
                  children: [
                    for (final review in data.items)
                      _ReviewTile(review: review),
                    if (data.pageInfo.hasNextPage) ...[
                      const SizedBox(height: AppSpacing.sm),
                      AppButton.secondary(
                        label: 'Load More',
                        icon: Icons.expand_more,
                        semanticLabel: 'Load more product reviews',
                        onPressed: () => setState(() => _first += _pageSize),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  void _track(String name) {
    ref
        .read(analyticsGatewayProvider)
        .track(
          AnalyticsEvent(
            name: name,
            parameters: {
              'productId': widget.product.id,
              'handle': widget.product.handle,
            },
          ),
        );
  }

  void _refreshReviews() {
    ref.invalidate(productReviewRepositoryProvider);
  }

  Future<void> _openReviewForm() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LooxInAppReviewScreen(
          productHandle: widget.product.handle,
          productTitle: widget.product.title,
        ),
      ),
    );
    if (mounted) _refreshReviews();
  }
}

class _ReviewSummaryView extends StatelessWidget {
  const _ReviewSummaryView({required this.summary});

  final ReviewSummary summary;

  @override
  Widget build(BuildContext context) {
    final average = summary.averageRating;
    final total = summary.totalReviews;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (average != null)
              Semantics(
                label: 'Average rating ${average.toStringAsFixed(1)} out of 5',
                child: Text(
                  '${average.toStringAsFixed(1)} / 5',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            if (total != null) Text('$total reviews'),
          ],
        ),
        if (summary.ratingBreakdown.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          for (var rating = 5; rating >= 1; rating--)
            if (summary.ratingBreakdown[rating] != null)
              _BreakdownRow(
                rating: rating,
                count: summary.ratingBreakdown[rating]!,
                total: total,
              ),
        ],
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.rating,
    required this.count,
    required this.total,
  });

  final int rating;
  final int count;
  final int? total;

  @override
  Widget build(BuildContext context) {
    final value = total == null || total == 0 ? 0.0 : count / total!;
    return Semantics(
      label: '$rating star reviews, $count total',
      child: Row(
        children: [
          SizedBox(width: 48, child: Text('$rating star')),
          Expanded(child: LinearProgressIndicator(value: value)),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(width: 32, child: Text('$count')),
        ],
      ),
    );
  }
}

class _ReviewSortControl extends StatelessWidget {
  const _ReviewSortControl({required this.value, required this.onChanged});

  final ReviewSort value;
  final ValueChanged<ReviewSort> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<ReviewSort>(
      initialValue: value,
      decoration: const InputDecoration(labelText: 'Sort reviews'),
      items: const [
        DropdownMenuItem(value: ReviewSort.latest, child: Text('Latest')),
        DropdownMenuItem(
          value: ReviewSort.highestRating,
          child: Text('Highest Rating'),
        ),
        DropdownMenuItem(
          value: ReviewSort.lowestRating,
          child: Text('Lowest Rating'),
        ),
        DropdownMenuItem(value: ReviewSort.helpful, child: Text('Featured')),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _ReviewTile extends StatelessWidget {
  const _ReviewTile({required this.review});

  final ProductReview review;

  @override
  Widget build(BuildContext context) {
    final customer = review.customerName ?? 'FLEXWOLF customer';
    final media = review.media;
    return Semantics(
      container: true,
      label: 'Review by $customer, ${review.rating} out of 5 stars',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    customer,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Text('${review.rating}/5'),
              ],
            ),
            if (review.verifiedPurchase == true)
              const Text('Verified purchase'),
            if ((review.title ?? '').isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                review.title!,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            Text(review.comment),
            const SizedBox(height: AppSpacing.xs),
            Text(
              MaterialLocalizations.of(context)
                  .formatShortDate(review.createdAt),
            ),
            if (review.helpfulCount != null)
              Text('${review.helpfulCount} found this helpful'),
            if (media.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              SizedBox(
                height: 88,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final item = media[index];
                    if (item.type == ReviewMediaType.video) {
                      return Semantics(
                        label: item.altText ?? 'Review video',
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AppRemoteImage(
                              imageUrl: item.thumbnailUrl ?? item.url,
                              semanticLabel: item.altText ?? 'Review video',
                            ),
                            const Icon(Icons.play_circle_outline, size: 36),
                          ],
                        ),
                      );
                    }
                    return AppRemoteImage(
                      imageUrl: item.url,
                      semanticLabel: item.altText ?? 'Review image',
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: AppSpacing.sm),
                  itemCount: media.length,
                ),
              ),
            ],
            const Divider(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _ReviewSummarySkeleton extends StatelessWidget {
  const _ReviewSummarySkeleton();

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      AppSkeletonLoader(height: 20),
      SizedBox(height: AppSpacing.sm),
      AppSkeletonLoader(height: 12),
    ],
  );
}

class _ReviewListSkeleton extends StatelessWidget {
  const _ReviewListSkeleton();

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      AppSkeletonLoader(height: 72),
      SizedBox(height: AppSpacing.sm),
      AppSkeletonLoader(height: 72),
    ],
  );
}

String _message(Object error) {
  if (error is AppException) return error.userMessage;
  return 'Try again later.';
}
