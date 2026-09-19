import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'final release audit keeps secrets and signing material out of source',
    () {
      final forbiddenFiles = <String>[
        'android/key.properties',
        'android/app/upload-keystore.jks',
        'android/app/google-services.json',
        'ios/Runner/GoogleService-Info.plist',
        'ios/Runner/AuthKey.p8',
        'lib/firebase_options.dart',
      ];

      for (final path in forbiddenFiles) {
        expect(
          File(path).existsSync(),
          isFalse,
          reason: '$path must not be committed',
        );
      }
    },
  );

  test('final release audit documents client ownership and deployment dependencies', () {
    final handover = File('docs/PHASE_11_FINAL_PRODUCTION_READINESS.md')
        .readAsStringSync();

    expect(handover, contains('FLEXWOLF GitHub'));
    expect(handover, contains('Firebase ownership'));
    expect(handover, contains('Shopify ownership'));
    expect(handover, contains('Apple Developer'));
    expect(handover, contains('Google Play'));
    expect(handover, contains('CLIENT DEPENDENCY'));
  });
}
