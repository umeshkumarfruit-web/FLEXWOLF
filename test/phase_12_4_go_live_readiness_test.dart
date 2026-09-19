import 'dart:io';

import 'package:flexwolf/app/config/app_config.dart';
import 'package:flexwolf/app/config/app_environment.dart';
import 'package:flexwolf/app/router/deep_link_contract.dart';
import 'package:flexwolf/app/router/route_names.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('go-live production config is release-safe by default', () {
    final config = AppConfig.forEnvironment(AppEnvironment.production);

    expect(config.environment, AppEnvironment.production);
    expect(config.backendBaseUrl, startsWith('https://'));
    expect(config.featureFlags.enableDiagnostics, isFalse);
    expect(config.allowsVerboseLogging, isFalse);
    expect(config.allowsProductionSideEffects, isTrue);
    expect(config.networkTimeout, const Duration(seconds: 15));
    expect(config.release.version, '1.0.0');
    expect(config.release.buildNumber, '1');
  });

  test(
    'go-live store config includes Android and iOS deep link preparation',
    () {
      final manifest = File('android/app/src/main/AndroidManifest.xml')
          .readAsStringSync();
      final entitlements = File('ios/Runner/Runner.entitlements')
          .readAsStringSync();

      expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
      expect(manifest, contains('android:autoVerify="true"'));
      expect(manifest, contains('android:pathPrefix="/products"'));
      expect(manifest, contains('android:pathPrefix="/collections"'));
      expect(entitlements, contains('aps-environment'));
      expect(entitlements, contains('applinks:flexwolf.com'));
    },
  );

  test('go-live deep links cover verification targets safely', () {
    const parser = DeepLinkParser();

    expect(parser.parse('/products/flex-tee').route, '/shop/products/flex-tee');
    expect(
      parser.parse('/collections/training').route,
      '/shop/collections/training',
    );
    expect(parser.parse('/wishlist').route, AppRoutes.wishlist);
    expect(parser.parse('/account/orders/1001').route, AppRoutes.account);
    expect(parser.parse('/checkout').route, AppDeepLinks.checkout);
  });

  test('go-live secret files are absent from repository', () {
    for (final path in <String>[
      'android/key.properties',
      'android/app/google-services.json',
      'ios/Runner/GoogleService-Info.plist',
      'lib/firebase_options.dart',
    ]) {
      expect(
        File(path).existsSync(),
        isFalse,
        reason: '$path must be supplied outside source control',
      );
    }
  });
}
