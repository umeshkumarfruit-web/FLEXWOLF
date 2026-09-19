import 'package:flexwolf/app/theme/app_theme.dart';
import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/layout/responsive_page_padding.dart';
import 'package:flexwolf/core/widgets/app_badge.dart';
import 'package:flexwolf/core/widgets/app_button.dart';
import 'package:flexwolf/core/widgets/app_empty_state.dart';
import 'package:flexwolf/core/widgets/app_error_state.dart';
import 'package:flexwolf/core/widgets/app_loading_indicator.dart';
import 'package:flexwolf/core/widgets/app_network_status_banner.dart';
import 'package:flexwolf/core/widgets/app_price.dart';
import 'package:flexwolf/core/widgets/app_product_card_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FLEXWOLF design tokens stay neutral and touch-friendly', () {
    expect(AppColors.brand, AppColors.black);
    expect(AppColors.background, AppColors.white);
    expect(AppTouchTargets.minimum, greaterThanOrEqualTo(48));
    expect(AppButtonSizes.minHeight, greaterThanOrEqualTo(48));
    expect(AppTypography.letterSpacing, 0);
    expect(AppAspectRatios.productCard, closeTo(0.8, 0.001));
  });

  testWidgets('primary button exposes accessible button semantics', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: AppButton.primary(label: 'Quick add', onPressed: () {}),
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel('Quick add'), findsWidgets);
    final size = tester.getSize(find.byType(FilledButton));
    expect(size.height, greaterThanOrEqualTo(AppTouchTargets.minimum));
  });

  test('responsive padding increases on larger phones', () {
    expect(
      ResponsivePagePadding.horizontalPaddingFor(340),
      AppScreenPadding.compact,
    );
    expect(
      ResponsivePagePadding.horizontalPaddingFor(620),
      AppScreenPadding.comfortable,
    );
  });

  testWidgets('loading, empty, and retry states render accessible states', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const AppLoadingIndicator(label: 'Loading products'),
      ),
    );
    expect(find.bySemanticsLabel('Loading products'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const AppEmptyState(
          title: 'No products',
          message: 'Try again later.',
        ),
      ),
    );
    expect(find.text('No products'), findsOneWidget);
    expect(find.text('Try again later.'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: AppErrorState(
          error: const AppException(
            kind: AppErrorKind.network,
            message: 'offline',
            isRetryable: true,
          ),
          onRetry: () {},
        ),
      ),
    );
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('retry state scrolls in constrained mobile layouts', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              height: 160,
              child: AppErrorState(
                error: const AppException(
                  kind: AppErrorKind.network,
                  message: 'A longer production readiness error message that still needs to remain accessible on compact mobile layouts.',
                  isRetryable: true,
                ),
                onRetry: () {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'network status banner exposes customer-facing recovery messaging',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: AppNetworkStatusBanner(
              message: 'Showing saved content while connection recovers.',
              status: AppNetworkStatus.stale,
              actionLabel: 'Retry',
              onAction: () {},
            ),
          ),
        ),
      );

      expect(
        find.text('Showing saved content while connection recovers.'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Semantics &&
              widget.properties.liveRegion == true &&
              widget.properties.label ==
                  'Showing saved content while connection recovers. Retry',
        ),
        findsOneWidget,
      );
    },
  );
  testWidgets(
    'product card shell renders image, badge, title, and sale price',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SizedBox(
              width: 180,
              child: AppProductCardShell(
                title: 'Flex Arm Tank',
                subtitle: 'Black / Medium',
                badge: const AppBadge(label: 'NEW'),
                image: const ColoredBox(color: AppColors.neutral100),
                price: const AppPrice(
                  price: '\$16.99',
                  compareAtPrice: '\$22.00',
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Flex Arm Tank'), findsOneWidget);
      expect(find.text('Black / Medium'), findsOneWidget);
      expect(find.text('NEW'), findsOneWidget);
      expect(find.text('\$16.99'), findsOneWidget);
      expect(find.text('\$22.00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('product card keeps long prices visible at shop card width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(340, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              width: 146,
              height: 340,
              child: AppProductCardShell(
                title: 'FLEXWOLF Performance Training Shorts',
                subtitle: 'Available',
                image: ColoredBox(
                  key: ValueKey<String>('product-image'),
                  color: AppColors.neutral100,
                ),
                price: AppPrice(
                  price: 'USD 129.99',
                  compareAtPrice: 'USD 179.99',
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('USD 129.99'), findsOneWidget);
    expect(find.text('USD 179.99'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey<String>('product-image'))),
      const Size(146, 204),
    );
    expect(tester.takeException(), isNull);
  });
}
