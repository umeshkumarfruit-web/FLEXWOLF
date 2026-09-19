import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/features/reviews/data/review_providers.dart';
import 'package:flexwolf/features/reviews/domain/product_reviews.dart';
import 'package:flexwolf/features/shop/domain/pagination.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'review cache de-duplicates identical summary and list requests',
    () async {
      final delegate = _CountingReviewRepository();
      final repository = CachedProductReviewRepository(delegate);
      const productId = 'gid://shopify/Product/1';
      const productHandle = 'training-tee';
      final query = ReviewQuery(
        productId: productId,
        productHandle: productHandle,
        pagination: const PaginationRequest(first: 5),
      );

      await Future.wait([
        repository.fetchSummary(
          productId: productId,
          productHandle: productHandle,
        ),
        repository.fetchSummary(
          productId: productId,
          productHandle: productHandle,
        ),
        repository.fetchReviews(query),
        repository.fetchReviews(query),
      ]);

      expect(delegate.summaryCalls, 1);
      expect(delegate.listCalls, 1);
    },
  );

  test(
    'client dependency repository reports reviews platform blocker',
    () async {
      const repository = ClientDependencyReviewRepository();

      expect(
        repository.fetchSummary(productId: '1', productHandle: 'tee'),
        throwsA(
          isA<AppException>().having(
            (error) => error.code,
            'code',
            'reviews_not_configured',
          ),
        ),
      );
    },
  );
}

class _CountingReviewRepository implements ProductReviewRepository {
  var summaryCalls = 0;
  var listCalls = 0;

  @override
  Future<ReviewSummary> fetchSummary({
    required String productId,
    required String productHandle,
  }) async {
    summaryCalls += 1;
    return const ReviewSummary(averageRating: 4.5, totalReviews: 2);
  }

  @override
  Future<PaginatedResult<ProductReview>> fetchReviews(ReviewQuery query) async {
    listCalls += 1;
    return const PaginatedResult<ProductReview>(
      items: <ProductReview>[],
      pageInfo: PageInfo(hasNextPage: false),
    );
  }

  @override
  Future<ReviewSubmissionResult> submitReview(
    ReviewSubmission submission,
  ) async {
    return const ReviewSubmissionResult(reviewId: 'review-1');
  }
}
