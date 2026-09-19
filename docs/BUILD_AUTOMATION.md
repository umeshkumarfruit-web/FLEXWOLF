# FLEXWOLF Build Automation

## Local Validation

Run these commands from the repository root:

```bash
flutter analyze
flutter test
flutter build apk --debug
flutter build appbundle
```

## Local Android Builds

The reusable local automation script reads version data from `pubspec.yaml`:

```powershell
.\tools\build_android.ps1
```

Targeted builds:

```powershell
.\tools\build_android.ps1 -Target debug-apk
.\tools\build_android.ps1 -Target release-apk
.\tools\build_android.ps1 -Target appbundle
```

Debug APK:

```bash
flutter build apk --debug
```

Release APK:

```bash
flutter build apk --release
```

Android App Bundle:

```bash
flutter build appbundle --release
```

Flutter reads the release version and build number from `pubspec.yaml`.

## iOS Preparation

iOS release automation is prepared but unsigned:

```bash
flutter build ios --release --no-codesign
```

Signed iOS distribution requires Apple certificates, provisioning profiles, and App Store Connect API credentials in GitHub Secrets.
