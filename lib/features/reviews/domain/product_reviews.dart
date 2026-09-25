import 'package:flexwolf/features/shop/domain/pagination.dart';

enum ReviewSort { latest, highestRating, lowestRating, helpful }

class ReviewSummary {
  const ReviewSummary({
    this.averageRating,
    this.totalReviews,
    this.ratingBreakdown = const <int, int>{},
  });

  final double? averageRating;
  final int? totalReviews;
  final Map<int, int> ratingBreakdown;

  bool get hasData =>
      averageRating != null ||
      totalReviews != null ||
      ratingBreakdown.isNotEmpty;
}

class ReviewMedia {
  const ReviewMedia({
    required this.url,
    required this.type,
    this.thumbnailUrl,
    this.altText,
  });

  final String url;
  final ReviewMediaType type;
  final String? thumbnailUrl;
  final String? altText;
}

enum ReviewMediaType { image, video }

class ProductReview {
  const ProductReview({
    required this.id,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.customerName,
    this.title,
    this.verifiedPurchase,
    this.helpfulCount,
    this.media = const <ReviewMedia>[],
  });

  final String id;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final String? customerName;
  final String? title;
  final bool? verifiedPurchase;
  final int? helpfulCount;
  final List<ReviewMedia> media;
}

class ReviewQuery {
  const ReviewQuery({
    required this.productId,
    required this.productHandle,
    required this.pagination,
    this.sort = ReviewSort.latest,
  });

  final String productId;
  final String productHandle;
  final PaginationRequest pagination;
  final ReviewSort sort;

  String get cacheKey =>
      '$productId|$productHandle|${sort.name}|${pagination.first}|${pagination.after ?? ''}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewQuery && cacheKey == other.cacheKey;

  @override
  int get hashCode => cacheKey.hashCode;
}

class ReviewSubmission {
  const ReviewSubmission({
    required this.productId,
    required this.productHandle,
    required this.rating,
    required this.title,
    required this.comment,
    this.customerName,
    this.imageAttachmentPaths = const <String>[],
  });

  final String productId;
  final String productHandle;
  final int rating;
  final String title;
  final String comment;
  final String? customerName;
  final List<String> imageAttachmentPaths;
}

class ReviewSubmissionResult {
  const ReviewSubmissionResult({
    required this.reviewId,
    this.pendingModeration = true,
  });

  final String reviewId;
  final bool pendingModeration;
}

abstract interface class ProductReviewRepository {
  Future<ReviewSummary> fetchSummary({
    required String productId,
    required String productHandle,
  });

  Future<PaginatedResult<ProductReview>> fetchReviews(ReviewQuery query);

  Future<ReviewSubmissionResult> submitReview(ReviewSubmission submission);
}
