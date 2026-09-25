import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/features/reviews/domain/product_reviews.dart';
import 'package:flexwolf/features/reviews/data/loox_review_repository.dart';
import 'package:flexwolf/features/shop/domain/pagination.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final productReviewRepositoryProvider = Provider<ProductReviewRepository>((
  ref,
) {
  const publicStoreId = String.fromEnvironment(
    'LOOX_PUBLIC_STORE_ID',
    defaultValue: 'kIPA3sM3MY.59e70e3aec7ca82462ab50f3e8c37df302b5de0b6e10896b36c0786a2f6e0be6',
  );
  return CachedProductReviewRepository(
    publicStoreId.isEmpty
        ? const ClientDependencyReviewRepository()
        : LooxReviewRepository(publicStoreId: publicStoreId),
  );
});

final reviewSummaryProvider = FutureProvider.autoDispose
    .family<ReviewSummary, ReviewProductKey>((ref, key) {
      return ref
          .watch(productReviewRepositoryProvider)
          .fetchSummary(
            productId: key.productId,
            productHandle: key.productHandle,
          );
    });

final reviewListProvider = FutureProvider.autoDispose
    .family<PaginatedResult<ProductReview>, ReviewQuery>((ref, query) {
      return ref.watch(productReviewRepositoryProvider).fetchReviews(query);
    });

class ReviewProductKey {
  const ReviewProductKey({
    required this.productId,
    required this.productHandle,
  });

  final String productId;
  final String productHandle;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewProductKey &&
          productId == other.productId &&
          productHandle == other.productHandle;

  @override
  int get hashCode => Object.hash(productId, productHandle);
}

class CachedProductReviewRepository implements ProductReviewRepository {
  CachedProductReviewRepository(this._delegate);

  final ProductReviewRepository _delegate;
  final Map<String, Future<ReviewSummary>> _summaryRequests =
      <String, Future<ReviewSummary>>{};
  final Map<String, Future<PaginatedResult<ProductReview>>> _reviewRequests =
      <String, Future<PaginatedResult<ProductReview>>>{};

  @override
  Future<ReviewSummary> fetchSummary({
    required String productId,
    required String productHandle,
  }) {
    final key = '$productId|$productHandle';
    return _summaryRequests.putIfAbsent(key, () async {
      try {
        return await _delegate.fetchSummary(
          productId: productId,
          productHandle: productHandle,
        );
      } catch (_) {
        _summaryRequests.remove(key);
        rethrow;
      }
    });
  }

  @override
  Future<PaginatedResult<ProductReview>> fetchReviews(ReviewQuery query) {
    return _reviewRequests.putIfAbsent(query.cacheKey, () async {
      try {
        return await _delegate.fetchReviews(query);
      } catch (_) {
        _reviewRequests.remove(query.cacheKey);
        rethrow;
      }
    });
  }

  @override
  Future<ReviewSubmissionResult> submitReview(ReviewSubmission submission) {
    _summaryRequests.remove(
      '${submission.productId}|${submission.productHandle}',
    );
    _reviewRequests.removeWhere(
      (key, value) => key.startsWith(
        '${submission.productId}|${submission.productHandle}|',
      ),
    );
    return _delegate.submitReview(submission);
  }
}

class ClientDependencyReviewRepository implements ProductReviewRepository {
  const ClientDependencyReviewRepository();

  AppException get _pending => const AppException(
    kind: AppErrorKind.unavailable,
    message: 'Ratings and reviews are temporarily unavailable.',
    code: 'reviews_not_configured',
    isRetryable: true,
  );

  @override
  Future<ReviewSummary> fetchSummary({
    required String productId,
    required String productHandle,
  }) async {
    throw _pending;
  }

  @override
  Future<PaginatedResult<ProductReview>> fetchReviews(ReviewQuery query) async {
    throw _pending;
  }

  @override
  Future<ReviewSubmissionResult> submitReview(
    ReviewSubmission submission,
  ) async {
    throw _pending;
  }
}
