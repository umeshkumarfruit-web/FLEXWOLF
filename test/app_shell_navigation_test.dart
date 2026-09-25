import 'package:flexwolf/app/app.dart';
import 'package:flexwolf/app/config/app_config.dart';
import 'package:flexwolf/app/config/app_environment.dart';
import 'package:flexwolf/app/router/route_names.dart';
import 'package:flexwolf/core/services/service_registry.dart';
import 'package:flexwolf/core/storage/local_storage.dart';
import 'package:flexwolf/features/home/app_section.dart';
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

  testWidgets('home shows header and drawer navigation', (tester) async {
    await tester.pumpWidget(await _returningUserApp());
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('FLEXWOLF'), findsOneWidget);
    expect(find.bySemanticsLabel('Search FLEXWOLF'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();
    for (final section in AppSection.values) {
      await _scrollDrawerTo(tester, section.label.toUpperCase());
      expect(
        find.widgetWithText(ListTile, section.label.toUpperCase()),
        findsOneWidget,
      );
    }
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

  testWidgets('drawer and bottom navigation switch top-level destinations', (
    tester,
  ) async {
    await tester.pumpWidget(await _returningUserApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();
    await _scrollDrawerTo(tester, 'SHOP');
    await tester.tap(find.widgetWithText(ListTile, 'SHOP'));
    await tester.pumpAndSettle();
    expect(find.text('All Products'), findsOneWidget);

    await tester.tap(find.text('Account'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome back.'), findsOneWidget);

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.bySemanticsLabel('FLEXWOLF'), findsOneWidget);
  });

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

  testWidgets('account screen offers optional sign in for guest shoppers', (
    tester,
  ) async {
    await tester.pumpWidget(await _returningUserApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();
    await _scrollDrawerTo(tester, 'ACCOUNT');
    await tester.tap(find.widgetWithText(ListTile, 'ACCOUNT'));
    await tester.pumpAndSettle();
    expect(find.text('Customer account setup is pending'), findsOneWidget);
    await tester.drag(find.byType(ListView).last, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Continue as Guest'), findsNothing);
    expect(
      find.text('Your existing flexwolf.co account and orders will appear here after Shopify account setup.'),
      findsOneWidget,
    );
    expect(find.text('Login with FLEXWOLF'), findsNothing);
  });
  testWidgets('navigation remains usable on narrow mobile widths', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(340, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(await _returningUserApp());
    await tester.pumpAndSettle();

    expect(find.byTooltip('Open menu'), findsOneWidget);
    await tester.tap(find.byTooltip('Open menu'));
    await tester.pumpAndSettle();
    for (final section in AppSection.values) {
      await _scrollDrawerTo(tester, section.label.toUpperCase());
      expect(
        find.widgetWithText(ListTile, section.label.toUpperCase()),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });
}

Future<void> _scrollDrawerTo(WidgetTester tester, String label) async {
  await tester.scrollUntilVisible(
    find.widgetWithText(ListTile, label),
    300,
    scrollable: find
        .descendant(of: find.byType(Drawer), matching: find.byType(Scrollable))
        .first,
  );
  await tester.pumpAndSettle();
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
