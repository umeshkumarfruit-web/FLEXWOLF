import 'package:flexwolf/app/app.dart';
import 'package:flexwolf/app/config/app_config.dart';
import 'package:flexwolf/app/config/app_environment.dart';
import 'package:flexwolf/core/services/service_registry.dart';
import 'package:flexwolf/core/storage/local_storage.dart';
import 'package:flexwolf/core/widgets/flexwolf_logo.dart';
import 'package:flexwolf/features/onboarding/data/onboarding_repository.dart';
import 'package:flexwolf/features/onboarding/domain/customer_preferences.dart';
import 'package:flexwolf/features/onboarding/domain/onboarding_snapshot.dart';
import 'package:flexwolf/features/onboarding/domain/preference_option.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('preference catalog is configurable domain data', () {
    expect(
      FlexwolfPreferenceCatalog.catalog.categories.map(
        (option) => option.label,
      ),
      ['Tees', 'Tanks', 'Shorts', 'Sweats', 'New Drops'],
    );
    expect(
      FlexwolfPreferenceCatalog.catalog.sizes.map((option) => option.label),
      ['S', 'M', 'L', 'XL', 'XXL'],
    );
  });

  test('repository persists onboarding and preferences locally', () async {
    final storage = InMemoryLocalStorage();
    final repository = OnboardingRepository(storage);

    expect((await repository.load()).status, OnboardingStatus.firstLaunch);

    await repository.markStarted();
    expect((await repository.load()).status, OnboardingStatus.started);

    await repository.complete(
      const CustomerPreferences(categoryIds: ['tees'], sizeIds: ['xl']),
    );
    final returning = await repository.load();

    expect(returning.status, OnboardingStatus.returningUser);
    expect(returning.preferences.categoryIds, ['tees']);
    expect(returning.preferences.sizeIds, ['xl']);
  });

  test(
    'continue as guest persists guest mode without customer account',
    () async {
      final repository = OnboardingRepository(InMemoryLocalStorage());

      await repository.continueAsGuest();
      final snapshot = await repository.load();

      expect(snapshot.status, OnboardingStatus.returningUser);
      expect(snapshot.isGuest, isTrue);
      expect(snapshot.shouldShowOnboarding, isFalse);
    },
  );

  test(
    'SharedPreferencesLocalStorage writes through the LocalStorage abstraction',
    () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final preferences = await SharedPreferences.getInstance();
      final storage = SharedPreferencesLocalStorage(preferences);

      await storage.writeString('onboarding.status', 'completed');
      await storage.writeBool('onboarding.guest_mode', true);

      expect(await storage.readString('onboarding.status'), 'completed');
      expect(await storage.readBool('onboarding.guest_mode'), isTrue);
    },
  );
  testWidgets('first launch renders onboarding welcome', (tester) async {
    await tester.pumpWidget(_testApp(InMemoryLocalStorage()));
    await tester.pumpAndSettle();

    expect(find.text('WELCOME TO THE PACK'), findsOneWidget);
    expect(find.text('Choose preferences'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);
    expect(find.text('Skip for now'), findsOneWidget);
  });

  testWidgets('skip hides onboarding for returning users', (tester) async {
    final storage = InMemoryLocalStorage();

    await tester.pumpWidget(_testApp(storage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip for now'));
    await tester.pumpAndSettle();

    expect(find.byType(FlexwolfLogo), findsWidgets);
    expect(
      (await OnboardingRepository(storage).load()).shouldShowOnboarding,
      isFalse,
    );
  });

  testWidgets('continue as guest enters the app shell', (tester) async {
    final storage = InMemoryLocalStorage();

    await tester.pumpWidget(_testApp(storage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue as Guest'));
    await tester.pumpAndSettle();

    expect(find.byType(FlexwolfLogo), findsWidgets);
    expect((await OnboardingRepository(storage).load()).isGuest, isTrue);
  });

  testWidgets('preferences can be selected, deselected, and saved', (
    tester,
  ) async {
    final storage = InMemoryLocalStorage();

    await tester.pumpWidget(_testApp(storage));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose preferences'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tees'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tees'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tanks'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('XL'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save preferences'));
    await tester.pumpAndSettle();

    final snapshot = await OnboardingRepository(storage).load();
    expect(find.byType(FlexwolfLogo), findsWidgets);
    expect(snapshot.preferences.categoryIds, ['tanks']);
    expect(snapshot.preferences.sizeIds, ['xl']);
  });

  testWidgets('returning users bypass onboarding', (tester) async {
    final storage = InMemoryLocalStorage();
    await storage.writeString('onboarding.status', 'completed');

    await tester.pumpWidget(_testApp(storage));
    await tester.pumpAndSettle();

    expect(find.text('WELCOME TO THE PACK'), findsNothing);
    expect(find.byType(FlexwolfLogo), findsWidgets);
  });

  testWidgets('onboarding remains usable on narrow mobile widths', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(340, 720));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(_testApp(InMemoryLocalStorage()));
    await tester.pumpAndSettle();

    expect(find.text('WELCOME TO THE PACK'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
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
