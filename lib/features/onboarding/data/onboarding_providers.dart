import 'package:flexwolf/core/services/service_registry.dart';
import 'package:flexwolf/features/onboarding/data/onboarding_repository.dart';
import 'package:flexwolf/features/onboarding/domain/onboarding_snapshot.dart';
import 'package:flexwolf/features/onboarding/domain/preference_option.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final preferenceCatalogProvider = Provider<PreferenceCatalog>((ref) {
  return FlexwolfPreferenceCatalog.catalog;
});

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepository(ref.watch(localStorageProvider));
});

final onboardingSnapshotProvider = FutureProvider<OnboardingSnapshot>((ref) {
  return ref.watch(onboardingRepositoryProvider).load();
});
