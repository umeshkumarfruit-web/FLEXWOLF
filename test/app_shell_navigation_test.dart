import 'package:flexwolf/app/app.dart';
import 'package:flexwolf/app/config/app_config.dart';
import 'package:flexwolf/app/config/app_environment.dart';
import 'package:flexwolf/app/router/route_names.dart';
import 'package:flexwolf/core/services/service_registry.dart';
import 'package:flexwolf/core/storage/local_storage.dart';
import 'package:flexwolf/features/home/app_section.dart';
import 'package:flexwolf/features/home/app_main_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('app sections define the top-level destinations', () {
    expect(AppSection.values.map((section) => section.label), [
      'Home',
      'Shop',
      'Search',
      'Wishlist',
      'Support',
      'Account',
    ]);
    expect(AppSection.shop.path, AppRoutes.shop);
    expect(AppSection.support.path, AppRoutes.support);
    expect(AppSection.account.routeName, AppRouteNames.account);
  });

  testWidgets('app shell renders FLEXWOLF header and main navigation', (
    tester,
  ) async {
    await tester.pumpWidget(await _returningUserApp());
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('FLEXWOLF'), findsOneWidget);
    expect(find.bySemanticsLabel('Search FLEXWOLF'), findsOneWidget);
    for (final section in AppMainNavigationBar.sections) {
      expect(find.text(section.label), findsOneWidget);
    }
    expect(find.textContaining('Summer Sale Up to 45% off'), findsOneWidget);
  });

  testWidgets('hamburger menu lets the customer switch dark and light themes', (
    tester,
  ) async {
    await tester.pumpWidget(await _returningUserApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();
    expect(find.text('DARK MODE'), findsOneWidget);

    await tester.tap(find.text('DARK MODE'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.dark,
    );
    expect(find.text('LIGHT MODE'), findsOneWidget);

    await tester.tap(find.text('LIGHT MODE'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(Scaffold).first)).brightness,
      Brightness.light,
    );
  });

  testWidgets(
    'bottom navigation switches top-level destinations without stacks',
    (tester) async {
      await tester.pumpWidget(await _returningUserApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Shop'));
      await tester.pumpAndSettle();
      expect(find.text('All Products'), findsOneWidget);

      await tester.tap(find.text('Account'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome back.'), findsOneWidget);

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Summer Sale Up to 45% off'), findsOneWidget);
    },
  );

  testWidgets('header search action switches to search shell', (tester) async {
    await tester.pumpWidget(await _returningUserApp());
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Search FLEXWOLF'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Search for...'), findsOneWidget);
  });

  testWidgets(
    'wishlist lives next to search in the header and Account remains reachable',
    (tester) async {
      await tester.pumpWidget(await _returningUserApp());
      await tester.pumpAndSettle();
      final bottom = find.byType(NavigationBar);
      expect(
        find.descendant(of: bottom, matching: find.text('Search')),
        findsNothing,
      );
      expect(
        find.descendant(of: bottom, matching: find.text('Wishlist')),
        findsNothing,
      );
      await tester.tap(find.bySemanticsLabel('Wishlist FLEXWOLF'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.tap(
        find.descendant(of: bottom, matching: find.text('Account')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Welcome back.'), findsOneWidget);
    },
  );

  testWidgets('account screen requires authentication for shopping', (
    tester,
  ) async {
    await tester.pumpWidget(await _returningUserApp());
    await tester.pumpAndSettle();

    final bottomNavigation = find.byType(NavigationBar);
    await tester.tap(
      find.descendant(of: bottomNavigation, matching: find.text('Account')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Create account'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Continue as Guest'), findsNothing);
    expect(
      find.text(
        'A FLEXWOLF account is required to add items, use your bag, and checkout.',
      ),
      findsOneWidget,
    );
    expect(find.text('Login with FLEXWOLF'), findsOneWidget);
  });
  testWidgets('navigation remains usable on narrow mobile widths', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(340, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(await _returningUserApp());
    await tester.pumpAndSettle();

    for (final section in AppMainNavigationBar.sections) {
      expect(find.text(section.label), findsOneWidget);
    }
    expect(tester.takeException(), isNull);
  });
}

Future<Widget> _returningUserApp() async {
  final storage = InMemoryLocalStorage();
  await storage.writeString('onboarding.status', 'completed');
  return _testApp(storage);
}

Widget _testApp(LocalStorage storage) {
  return ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(
        AppConfig.forEnvironment(AppEnvironment.development),
      ),
      localStorageProvider.overrideWithValue(storage),
    ],
    child: const FlexwolfApp(),
  );
}
