import 'dart:convert';
import 'dart:io';

import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/features/reviews/domain/product_reviews.dart';
import 'package:flexwolf/features/shop/domain/pagination.dart';

class LooxReviewRepository implements ProductReviewRepository {
  LooxReviewRepository({required this.publicStoreId, HttpClient? httpClient})
    : _httpClient = httpClient ?? HttpClient();

  final String publicStoreId;
  final HttpClient _httpClient;

  String _shopifyId(String id) => id.split('/').last;

  Uri _endpoint(String path, [Map<String, String>? query]) => Uri.https(
    'storefront-api.loox.io',
    '/storefront/v1/store/${Uri.encodeComponent(publicStoreId)}/$path',
    query,
  );

  Future<Map<String, dynamic>> _get(Uri uri) async {
    try {
      final request = await _httpClient.getUrl(uri);
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      if (response.statusCode != HttpStatus.ok) {
        throw AppException(
          kind: AppErrorKind.unavailable,
          message: 'Loox reviews are unavailable (${response.statusCode}).',
          code: 'loox_http_${response.statusCode}',
          isRetryable: response.statusCode >= 500,
        );
      }
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Invalid Loox response.');
      }
      return decoded;
    } on AppException {
      rethrow;
    } on Object {
      throw const AppException(
        kind: AppErrorKind.unavailable,
        message: 'Loox reviews could not be loaded.',
        code: 'loox_request_failed',
        isRetryable: true,
      );
    }
  }

  @override
  Future<ReviewSummary> fetchSummary({
    required String productId,
    required String productHandle,
  }) async {
    final json = await _get(
      _endpoint('product-reviews/bottomline/${_shopifyId(productId)}'),
    );
    final distribution = json['ratingDistribution'];
    return ReviewSummary(
      averageRating: (json['averageRating'] as num?)?.toDouble(),
      totalReviews: (json['totalReviews'] as num?)?.toInt(),
      ratingBreakdown: distribution is Map
          ? {
              for (var rating = 1; rating <= 5; rating++)
                rating: (distribution['$rating'] as num?)?.toInt() ?? 0,
            }
          : const <int, int>{},
    );
  }

  @override
  Future<PaginatedResult<ProductReview>> fetchReviews(ReviewQuery query) async {
    final sort = switch (query.sort) {
      ReviewSort.latest => 'date',
      ReviewSort.highestRating || ReviewSort.lowestRating => 'rating',
      ReviewSort.helpful => 'featured',
    };
    final json = await _get(
      _endpoint('product-reviews', {
        'product_id': _shopifyId(query.productId),
        'sort': sort,
        'direction': query.sort == ReviewSort.lowestRating ? 'asc' : 'desc',
        'page': '1',
        'limit': '${query.pagination.first}',
      }),
    );
    final rows = json['reviews'];
    final pagination = json['pagination'];
    if (rows is! List || pagination is! Map) {
      throw const FormatException('Invalid Loox reviews response.');
    }
    return PaginatedResult(
      items: rows.whereType<Map<String, dynamic>>().map(_parseReview).toList(),
      pageInfo: PageInfo(hasNextPage: pagination['hasMore'] == true),
    );
  }

  ProductReview _parseReview(Map<String, dynamic> row) {
    final reviewer = row['reviewer'];
    final media = row['media'];
    return ProductReview(
      id: '${row['id']}',
      rating: (row['rating'] as num).toInt(),
      comment: row['body'] as String? ?? '',
      createdAt: DateTime.parse(row['date'] as String),
      customerName: reviewer is Map ? reviewer['name'] as String? : null,
      verifiedPurchase: row['verified'] as bool?,
      media: media is List
          ? media
                .whereType<Map<String, dynamic>>()
                .map(
                  (item) => ReviewMedia(
                    url: item['url'] as String,
                    type: item['type'] == 'video'
                        ? ReviewMediaType.video
                        : ReviewMediaType.image,
                    thumbnailUrl: item['thumbnailUrl'] as String?,
                  ),
                )
                .toList()
          : const <ReviewMedia>[],
    );
  }

  @override
  Future<ReviewSubmissionResult> submitReview(ReviewSubmission submission) {
    throw const AppException(
      kind: AppErrorKind.unavailable,
      message: 'Loox does not support review submission through its API.',
      code: 'loox_submission_unavailable',
    );
  }
}
