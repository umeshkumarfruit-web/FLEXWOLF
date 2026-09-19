import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flexwolf/core/services/service_registry.dart';
import 'package:flexwolf/core/widgets/app_button.dart';
import 'package:flexwolf/core/widgets/app_preference_chip.dart';
import 'package:flexwolf/core/widgets/flexwolf_logo.dart';
import 'package:flexwolf/features/onboarding/data/onboarding_providers.dart';
import 'package:flexwolf/features/onboarding/domain/customer_preferences.dart';
import 'package:flexwolf/integrations/analytics/analytics_boundary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingGate extends ConsumerWidget {
  const OnboardingGate({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(onboardingSnapshotProvider);

    return snapshot.when(
      data: (data) {
        if (!data.shouldShowOnboarding) {
          return child;
        }
        return OnboardingFlow(initialPreferences: data.preferences);
      },
      error: (error, stackTrace) => child,
      loading: () => const _OnboardingSplashFallback(),
    );
  }
}

class OnboardingFlow extends ConsumerStatefulWidget {
  const OnboardingFlow({required this.initialPreferences, super.key});

  final CustomerPreferences initialPreferences;

  @override
  ConsumerState<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends ConsumerState<OnboardingFlow> {
  bool _showPreferences = false;
  late Set<String> _selectedCategories;
  late Set<String> _selectedSizes;

  @override
  void initState() {
    super.initState();
    _selectedCategories = widget.initialPreferences.categoryIds.toSet();
    _selectedSizes = widget.initialPreferences.sizeIds.toSet();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markStarted());
  }

  Future<void> _markStarted() async {
    final repository = ref.read(onboardingRepositoryProvider);
    await repository.markStarted();
    await ref
        .read(analyticsGatewayProvider)
        .track(
          const AnalyticsEvent(name: AppAnalyticsEvents.onboardingStarted),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.sizeOf(context).height -
                  MediaQuery.paddingOf(context).vertical -
                  (AppSpacing.lg * 2),
            ),
            child: _showPreferences
                ? _preferencesStep(context)
                : _welcomeStep(context),
          ),
        ),
      ),
    );
  }

  Widget _welcomeStep(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FlexwolfLogo(),
        const SizedBox(height: AppSpacing.xxxl),
        Text(
          'WELCOME TO THE PACK',
          style: Theme.of(context).textTheme.displaySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Set your fit preferences now, or continue as guest and browse when the commerce screens arrive.',
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xxl),
        AppButton.primary(
          label: 'Choose preferences',
          onPressed: () => setState(() => _showPreferences = true),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton.secondary(
          label: 'Continue as Guest',
          onPressed: _continueAsGuest,
        ),
        const SizedBox(height: AppSpacing.xs),
        AppButton.text(label: 'Skip for now', onPressed: _skip),
      ],
    );
  }

  Widget _preferencesStep(BuildContext context) {
    final catalog = ref.watch(preferenceCatalogProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FlexwolfLogo(),
        const SizedBox(height: AppSpacing.xl),
        Text(
          'Dial in your preferences',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Optional selections help prepare future personalization without creating an account or syncing data yet.',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Categories', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final option in catalog.categories)
              AppPreferenceChip(
                label: option.label,
                selected: _selectedCategories.contains(option.id),
                onSelected: (selected) => _togglePreference(
                  id: option.id,
                  selected: selected,
                  target: _selectedCategories,
                  type: 'category',
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Sizes', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final option in catalog.sizes)
              AppPreferenceChip(
                label: option.label,
                selected: _selectedSizes.contains(option.id),
                onSelected: (selected) => _togglePreference(
                  id: option.id,
                  selected: selected,
                  target: _selectedSizes,
                  type: 'size',
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton.primary(
          label: 'Save preferences',
          onPressed: _savePreferences,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton.secondary(
          label: 'Continue as Guest',
          onPressed: _continueAsGuest,
        ),
        const SizedBox(height: AppSpacing.xs),
        AppButton.text(label: 'Skip for now', onPressed: _skip),
      ],
    );
  }

  Future<void> _togglePreference({
    required String id,
    required bool selected,
    required Set<String> target,
    required String type,
  }) async {
    setState(() {
      if (selected) {
        target.add(id);
      } else {
        target.remove(id);
      }
    });
    await ref
        .read(analyticsGatewayProvider)
        .track(
          AnalyticsEvent(
            name: AppAnalyticsEvents.preferenceSelected,
            parameters: <String, Object?>{
              'type': type,
              'id': id,
              'selected': selected,
            },
          ),
        );
  }

  Future<void> _continueAsGuest() async {
    await ref.read(onboardingRepositoryProvider).continueAsGuest();
    final analytics = ref.read(analyticsGatewayProvider);
    await analytics.track(
      const AnalyticsEvent(name: AppAnalyticsEvents.guestContinue),
    );
    await analytics.track(
      const AnalyticsEvent(name: AppAnalyticsEvents.onboardingSkipped),
    );
    ref.invalidate(onboardingSnapshotProvider);
  }

  Future<void> _skip() async {
    await ref.read(onboardingRepositoryProvider).skip();
    await ref
        .read(analyticsGatewayProvider)
        .track(
          const AnalyticsEvent(name: AppAnalyticsEvents.onboardingSkipped),
        );
    ref.invalidate(onboardingSnapshotProvider);
  }

  Future<void> _savePreferences() async {
    final preferences = CustomerPreferences(
      categoryIds: _selectedCategories.toList(growable: false)..sort(),
      sizeIds: _selectedSizes.toList(growable: false)..sort(),
    );
    await ref.read(onboardingRepositoryProvider).complete(preferences);
    final analytics = ref.read(analyticsGatewayProvider);
    await analytics.track(
      AnalyticsEvent(
        name: AppAnalyticsEvents.preferenceSaved,
        parameters: <String, Object?>{
          'category_count': preferences.categoryIds.length,
          'size_count': preferences.sizeIds.length,
        },
      ),
    );
    await analytics.track(
      const AnalyticsEvent(name: AppAnalyticsEvents.onboardingCompleted),
    );
    ref.invalidate(onboardingSnapshotProvider);
  }
}

class _OnboardingSplashFallback extends StatelessWidget {
  const _OnboardingSplashFallback();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.background,
      child: Center(child: FlexwolfLogo()),
    );
  }
}
