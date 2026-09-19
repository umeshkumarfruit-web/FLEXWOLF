import 'package:flexwolf/app/app.dart';
import 'package:flexwolf/app/config/app_config.dart';
import 'package:flexwolf/app/config/app_environment.dart';
import 'package:flexwolf/core/services/service_registry.dart';
import 'package:flexwolf/core/storage/local_storage.dart';
import 'package:flexwolf/core/storage/secure_storage.dart';
import 'package:flexwolf/integrations/shopify/shopify_providers.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flexwolf/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> bootstrap(AppEnvironment environment) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Product imagery can otherwise fill Flutter's 100 MB default cache on
  // image-heavy catalog screens. Keep enough decoded images for smooth
  // scrolling without retaining an excessive amount of memory.
  final imageCache = PaintingBinding.instance.imageCache;
  imageCache.maximumSize = 120;
  imageCache.maximumSizeBytes = 48 << 20;

  final config = AppConfig.forEnvironment(environment);
  // These independent platform calls used to run serially and delay the first
  // frame by their combined duration.
  final sharedPreferencesFuture = SharedPreferences.getInstance();
  final firebaseFuture = _initializeFirebase();
  final sharedPreferences = await sharedPreferencesFuture;
  await firebaseFuture;

  runApp(
    ProviderScope(
      overrides: [
        appConfigProvider.overrideWithValue(config),
        secureStorageProvider.overrideWithValue(const DeviceSecureStorage()),
        shopifyConfigProvider.overrideWithValue(config.shopify),
        localStorageProvider.overrideWithValue(
          SharedPreferencesLocalStorage(sharedPreferences),
        ),
      ],
      child: const FlexwolfApp(),
    ),
  );
}

Future<void> _initializeFirebase() async {
  if (Firebase.apps.isNotEmpty) return;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on UnsupportedError {
    return;
  } on Object {
    return;
  }
}
