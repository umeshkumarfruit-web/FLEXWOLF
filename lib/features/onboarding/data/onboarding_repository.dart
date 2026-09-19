import 'package:flexwolf/core/storage/local_storage.dart';
import 'package:flexwolf/features/onboarding/domain/customer_preferences.dart';
import 'package:flexwolf/features/onboarding/domain/onboarding_snapshot.dart';

class OnboardingRepository {
  const OnboardingRepository(this._storage);

  static const _statusKey = 'onboarding.status';
  static const _guestKey = 'onboarding.guest_mode';
  static const _preferencesKey = 'onboarding.preferences';

  final LocalStorage _storage;

  Future<OnboardingSnapshot> load() async {
    final rawStatus = await _storage.readString(_statusKey);
    final isGuest = await _storage.readBool(_guestKey) ?? false;
    final preferences = await loadPreferences();

    final status = switch (rawStatus) {
      'started' => OnboardingStatus.started,
      'skipped' || 'completed' => OnboardingStatus.returningUser,
      _ => OnboardingStatus.firstLaunch,
    };

    return OnboardingSnapshot(
      status: status,
      isGuest: isGuest,
      preferences: preferences,
    );
  }

  Future<CustomerPreferences> loadPreferences() async {
    final rawPreferences = await _storage.readString(_preferencesKey);
    if (rawPreferences == null || rawPreferences.isEmpty) {
      return const CustomerPreferences();
    }

    return CustomerPreferences.fromJsonString(rawPreferences);
  }

  Future<void> markStarted() async {
    await _storage.writeString(_statusKey, 'started');
  }

  Future<void> continueAsGuest() async {
    await _storage.writeBool(_guestKey, true);
    await _storage.writeString(_statusKey, 'skipped');
  }

  Future<void> skip() async {
    await _storage.writeString(_statusKey, 'skipped');
  }

  Future<void> complete(CustomerPreferences preferences) async {
    await savePreferences(preferences);
    await _storage.writeString(_statusKey, 'completed');
  }

  Future<void> savePreferences(CustomerPreferences preferences) async {
    await _storage.writeString(_preferencesKey, preferences.toJsonString());
  }

  Future<void> reset() async {
    await _storage.remove(_statusKey);
    await _storage.remove(_guestKey);
    await _storage.remove(_preferencesKey);
  }
}
