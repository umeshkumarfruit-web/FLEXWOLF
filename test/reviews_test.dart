import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/features/reviews/data/review_providers.dart';
import 'package:flexwolf/features/reviews/presentation/product_reviews_section.dart';
import 'package:flexwolf/features/shop/domain/product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  test('failed review requests can be retried', () async {
    final delegate = _FailOnceReviewRepository();
    final repository = CachedProductReviewRepository(delegate);
    const query = ReviewQuery(
      productId: 'gid://shopify/Product/1',
      productHandle: 'training-tee',
      pagination: PaginationRequest(first: 5),
    );

    await expectLater(
      repository.fetchSummary(
        productId: query.productId,
        productHandle: query.productHandle,
      ),
      throwsException,
    );
    await expectLater(repository.fetchReviews(query), throwsException);

    expect(
      (await repository.fetchSummary(
        productId: query.productId,
        productHandle: query.productHandle,
      )).averageRating,
      4.5,
    );
    expect((await repository.fetchReviews(query)).items, isEmpty);
    expect(delegate.summaryCalls, 2);
    expect(delegate.listCalls, 2);
  });

  testWidgets('reviews never open a storefront when provider is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productReviewRepositoryProvider.overrideWithValue(
            const ClientDependencyReviewRepository(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ProductReviewsSection(
              product: ProductSummary(
                id: 'gid://shopify/Product/1',
                handle: 'training-tee',
                title: 'Training Tee',
                availableForSale: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('View All Reviews'), findsOneWidget);
    expect(find.text('Write Review'), findsOneWidget);
  });

  testWidgets('rating and review list render natively', (tester) async {
    final repository = _CountingReviewRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productReviewRepositoryProvider.overrideWithValue(repository),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: ProductReviewsSection(
              product: ProductSummary(
                id: 'gid://shopify/Product/1',
                handle: 'training-tee',
                title: 'Training Tee',
                availableForSale: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('4.5 / 5'), findsOneWidget);
    await tester.tap(find.text('View All Reviews'));
    await tester.pumpAndSettle();
    expect(find.text('No reviews yet'), findsOneWidget);
    expect(repository.summaryCalls, 1);
    expect(repository.listCalls, 1);
  });
}

class _FailOnceReviewRepository extends _CountingReviewRepository {
  @override
  Future<ReviewSummary> fetchSummary({
    required String productId,
    required String productHandle,
  }) async {
    summaryCalls += 1;
    if (summaryCalls == 1) throw Exception('temporary failure');
    return const ReviewSummary(averageRating: 4.5, totalReviews: 2);
  }

  @override
  Future<PaginatedResult<ProductReview>> fetchReviews(ReviewQuery query) async {
    listCalls += 1;
    if (listCalls == 1) throw Exception('temporary failure');
    return const PaginatedResult<ProductReview>(
      items: <ProductReview>[],
      pageInfo: PageInfo(hasNextPage: false),
    );
  }
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
