import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('final client handover readiness', () {
    test('required final delivery documents exist', () {
      final requiredDocs = [
        'docs/PHASE_12_5_FINAL_CLIENT_HANDOVER.md',
        'docs/PHASE_12_5_FINAL_DELIVERY_REPORT.md',
        'docs/PHASE_12_5_CLIENT_DEPENDENCY_REPORT.md',
        'docs/PHASE_12_5_PRODUCTION_READINESS_REPORT.md',
      ];

      for (final path in requiredDocs) {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: '$path must exist');
        expect(file.readAsStringSync().trim(), isNotEmpty);
      }
    });

    test(
      'handover documentation keeps credential work as client dependency',
      () {
        final handover = File('docs/PHASE_12_5_FINAL_CLIENT_HANDOVER.md')
            .readAsStringSync();
        final dependencies = File('docs/PHASE_12_5_CLIENT_DEPENDENCY_REPORT.md')
            .readAsStringSync();

        for (final required in [
          'GitHub repository',
          'Firebase production project',
          'Shopify production store',
          'Apple Developer',
          'Google Play Console',
          'Android release keystore',
          'Klaviyo',
          'Gorgias',
          'Redo',
          'Reviews platform',
        ]) {
          expect('$handover\n$dependencies', contains(required));
        }
      },
    );

    test('repository does not contain committed production secret files', () {
      final forbiddenPaths = [
        '.env',
        'android/key.properties',
        'android/app/google-services.json',
        'ios/Runner/GoogleService-Info.plist',
        'lib/firebase_options.dart',
      ];

      for (final path in forbiddenPaths) {
        expect(
          File(path).existsSync(),
          isFalse,
          reason: '$path must stay out of git',
        );
      }
    });

    test('Shopify Admin API remains documented as backend-only', () {
      final architecture = File('docs/shopify/admin_api_requirements.md')
          .readAsStringSync();
      final source = File(
        'lib/integrations/shopify/admin/admin_api_requirements.dart',
      ).readAsStringSync();

      expect(architecture, contains('Admin API is not integrated in Flutter'));
      expect(source, contains('secure FLEXWOLF backend'));
    });
  });
}
