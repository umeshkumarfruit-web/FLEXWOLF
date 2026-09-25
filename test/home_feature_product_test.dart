import 'package:flexwolf/features/home/presentation/home_feature_product.dart';
import 'package:flexwolf/features/reviews/data/review_providers.dart';
import 'package:flexwolf/features/reviews/domain/product_reviews.dart';
import 'package:flexwolf/features/shop/domain/money.dart';
import 'package:flexwolf/features/shop/domain/pagination.dart';
import 'package:flexwolf/features/shop/domain/product.dart';
import 'package:flexwolf/features/shop/domain/product_variant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('feature product selects a pack and size in the app', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          productReviewRepositoryProvider.overrideWithValue(_Reviews()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HomeFeatureProduct(product: _product),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('★★★★★  (1356)  Reviews'), findsOneWidget);
    await tester.ensureVisible(find.text('Singles'));
    await tester.tap(find.text('Singles'));
    await tester.ensureVisible(find.text('M'));
    await tester.tap(find.text('M'));
    await tester.pumpAndSettle();
    expect(find.text('ADD TO BAG'), findsOneWidget);
    await tester.tap(find.text('Sizing Chart'));
    await tester.pumpAndSettle();
    expect(find.text('37 Inch'), findsOneWidget);
  });
}

final _product = ProductSummary(
  id: 'gid://shopify/Product/8623396815105',
  handle: 'flex-arm-tank',
  title: 'Flex Arm Tank',
  availableForSale: true,
  variants: [
    for (final size in ['S', 'M'])
      ProductVariant(
        id: 'gid://shopify/ProductVariant/$size',
        availableForSale: true,
        price: Money(amount: DecimalAmount.parse('1699'), currencyCode: 'INR'),
        selectedOptions: [
          const SelectedOption(name: 'Color', value: 'Black'),
          SelectedOption(name: 'Size', value: size),
        ],
      ),
  ],
);

class _Reviews implements ProductReviewRepository {
  @override
  Future<ReviewSummary> fetchSummary({
    required String productId,
    required String productHandle,
  }) async => const ReviewSummary(averageRating: 4.8, totalReviews: 1356);

  @override
  Future<PaginatedResult<ProductReview>> fetchReviews(
    ReviewQuery query,
  ) async =>
      const PaginatedResult(items: [], pageInfo: PageInfo(hasNextPage: false));

  @override
  Future<ReviewSubmissionResult> submitReview(
    ReviewSubmission submission,
  ) async => const ReviewSubmissionResult(reviewId: 'unused');
}
