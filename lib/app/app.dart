import 'package:flexwolf/app/config/app_config.dart';
import 'package:flexwolf/app/router/app_router.dart';
import 'package:flexwolf/app/theme/app_theme.dart';
import 'package:flexwolf/app/theme/theme_mode_controller.dart';
import 'package:flexwolf/core/lifecycle/app_lifecycle_observer.dart';
import 'package:flexwolf/core/services/service_registry.dart';
import 'package:flexwolf/features/notifications/data/notification_providers.dart';
import 'package:flexwolf/features/onboarding/onboarding.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FlexwolfApp extends ConsumerWidget {
  const FlexwolfApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final router = ref.watch(appRouterProvider);
    final themeModeController = ref.watch(appThemeModeControllerProvider);
    final logger = ref.watch(loggerProvider);
    ref.watch(notificationLifecycleProvider);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeModeController,
      builder: (context, themeMode, _) => AppLifecycleObserver(
        logger: logger,
        child: MaterialApp.router(
          title: config.appName,
          debugShowCheckedModeBanner: !config.environment.isProduction,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeMode,
          routerConfig: router,
          builder: (context, child) {
            return OnboardingGate(child: child ?? const SizedBox.shrink());
          },
        ),
      ),
    );
  }
}
