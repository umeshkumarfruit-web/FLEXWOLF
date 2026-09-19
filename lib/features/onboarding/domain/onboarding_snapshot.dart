import 'package:flexwolf/features/onboarding/domain/customer_preferences.dart';
import 'package:flutter/foundation.dart';

enum OnboardingStatus {
  firstLaunch,
  started,
  skipped,
  completed,
  returningUser,
}

@immutable
class OnboardingSnapshot {
  const OnboardingSnapshot({
    required this.status,
    required this.isGuest,
    required this.preferences,
  });

  final OnboardingStatus status;
  final bool isGuest;
  final CustomerPreferences preferences;

  bool get shouldShowOnboarding =>
      status == OnboardingStatus.firstLaunch ||
      status == OnboardingStatus.started;
}
