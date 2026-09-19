# FLEXWOLF CI/CD

Phase 11.2 establishes the build and release automation foundation without changing app behavior.

## Version Source

`pubspec.yaml` is the single version source:

```yaml
version: 1.0.0+1
```

- `1.0.0` is the semantic release version.
- `1` is the build number.
- Android receives `versionName` and `versionCode` from Flutter.
- iOS receives `CFBundleShortVersionString` and `CFBundleVersion` from Flutter.

Do not duplicate version values in workflow files, Gradle, Xcode, or release notes. Workflows read the value from `pubspec.yaml`.

## Workflows

- `.github/workflows/flutter_quality.yml`: reusable quality gate for `flutter analyze` and `flutter test`.
- `.github/workflows/android_build.yml`: reusable Android artifact workflow for debug APK, release APK, and release AAB.
- `.github/workflows/ios_release_prepare.yml`: prepared iOS release pipeline using `flutter build ios --release --no-codesign`.
- `.github/workflows/ci.yml`: default CI entrypoint for pull requests, `main`, `develop`, and manual runs.

## Required Checks

Build jobs depend on:

```bash
flutter analyze
flutter test
```

If either command fails, APK and AAB generation is blocked.

## Artifacts

Android artifacts:

- `build/app/outputs/flutter-apk/app-debug.apk`
- `build/app/outputs/flutter-apk/app-release.apk`
- `build/app/outputs/bundle/release/app-release.aab`

iOS prepared artifact:

- `build/ios/iphoneos/Runner.app`

## Secrets

Never commit signing keys, Firebase secrets, Shopify secrets, API keys, provisioning profiles, or service account files.

Use GitHub Secrets for future signed release jobs:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`
- `IOS_CERTIFICATE_BASE64`
- `IOS_CERTIFICATE_PASSWORD`
- `IOS_PROVISION_PROFILE_BASE64`
- `APP_STORE_CONNECT_API_KEY_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_API_KEY_BASE64`

The current Android Gradle configuration supports local or CI-provided `android/key.properties`, which remains ignored by git.
