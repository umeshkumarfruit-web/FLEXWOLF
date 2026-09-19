import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Android release manifest is prepared for launcher, push, and deep links',
    () {
      final manifest = File('android/app/src/main/AndroidManifest.xml')
          .readAsStringSync();

      expect(manifest, contains('android.permission.POST_NOTIFICATIONS'));
      expect(manifest, contains('android:label="@string/app_name"'));
      expect(manifest, contains('android:icon="@mipmap/ic_launcher"'));
      expect(manifest, contains('android:autoVerify="true"'));
      expect(manifest, contains('android:pathPrefix="/products"'));
      expect(manifest, contains('android:pathPrefix="/collections"'));
      expect(manifest, contains('android:pathPrefix="/account/orders"'));
      expect(manifest, contains('android:scheme="flexwolf"'));
    },
  );

  test('Android release version remains sourced from Flutter pubspec', () {
    final buildGradle = File('android/app/build.gradle.kts').readAsStringSync();

    expect(buildGradle, contains('versionCode = flutter.versionCode'));
    expect(buildGradle, contains('versionName = flutter.versionName'));
    expect(buildGradle, contains('manifestPlaceholders["deepLinkHost"]'));
  });

  test('iOS release metadata and capabilities are prepared', () {
    final info = File('ios/Runner/Info.plist').readAsStringSync();
    final entitlements = File('ios/Runner/Runner.entitlements')
        .readAsStringSync();
    final project = File('ios/Runner.xcodeproj/project.pbxproj')
        .readAsStringSync();

    expect(info, contains(r'$(PRODUCT_BUNDLE_IDENTIFIER)'));
    expect(info, contains(r'$(FLUTTER_BUILD_NAME)'));
    expect(info, contains(r'$(FLUTTER_BUILD_NUMBER)'));
    expect(info, contains('<string>flexwolf</string>'));
    expect(entitlements, contains('aps-environment'));
    expect(entitlements, contains('applinks:flexwolf.com'));
    expect(
      project,
      contains('PRODUCT_BUNDLE_IDENTIFIER = com.flexwolf.flexwolf;'),
    );
    expect(
      project,
      contains('CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;'),
    );
  });

  test('required release assets exist', () {
    expect(
      File('android/app/src/main/res/values/strings.xml').existsSync(),
      isTrue,
    );
    expect(
      File('android/app/src/main/res/drawable/launch_background.xml')
          .existsSync(),
      isTrue,
    );
    expect(
      File('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png')
          .existsSync(),
      isTrue,
    );
    expect(
      File('ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json')
          .existsSync(),
      isTrue,
    );
    expect(
      File('ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json')
          .existsSync(),
      isTrue,
    );
  });
}
