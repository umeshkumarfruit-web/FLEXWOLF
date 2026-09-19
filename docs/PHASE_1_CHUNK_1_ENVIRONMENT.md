# FLEXWOLF Phase 1 - Chunk 1 Environment Status

Status date: 2026-08-31

This document records Phase 1 Chunk 1 only. Phase 1 is not complete after this chunk.

## Machine

- Operating system: Microsoft Windows 11 Home Single Language
- OS version: 10.0.26200.9168, Windows 11 25H2
- CPU: AMD Ryzen 3 3250U with Radeon Graphics
- CPU architecture: x64
- CPU cores/threads: 2 cores, 4 logical processors
- RAM: about 6 GB installed
- Disk space at inspection:
  - C: 255 GB total, about 43 GB free
  - D: 537 GB total, about 531 GB free
  - E: 462 GB total, about 462 GB free
- PowerShell: Windows PowerShell 5.1.26100.9168
- Command Prompt: available

## Installed Tooling

- Git: 2.54.0.windows.1
- Flutter: 3.47.1 stable
- Dart: 3.13.1 stable
- Flutter SDK path: D:\develop\flutter-stable\flutter
- Flutter channel: stable
- Java on PATH: Microsoft OpenJDK 17.0.20
- Android Studio bundled JDK used by Flutter: C:\Program Files\Android\Android Studio1\jbr\bin\java.exe
- Android Studio bundled JDK version reported by Flutter: OpenJDK 25.0.2
- JAVA_HOME: C:\Program Files\Microsoft\jdk-17.0.20.8-hotspot\
- Android Studio: installed
  - C:\Program Files\Android\Android Studio
  - C:\Program Files\Android\Android Studio1
  - Build: AI-261.26222.65.2613.16025427
- Android SDK: C:\Users\HP\AppData\Local\Android\Sdk
- ANDROID_HOME: C:\Users\HP\AppData\Local\Android\Sdk
- ANDROID_SDK_ROOT: C:\Users\HP\AppData\Local\Android\Sdk
- Android SDK platforms: android-35, android-36, android-37.0, android-37.1
- Android SDK platform-tools: installed
- Android SDK build-tools: 36.0.0, 37.0.0
- Android SDK command-line tools: latest installed
- Android Emulator: 37.1.11.0
- adb: 37.0.1, installed at C:\Users\HP\AppData\Local\Android\Sdk\platform-tools\adb.exe
- VS Code: 1.135.0 x64
- VS Code extensions installed:
  - dart-code.dart-code 3.140.0
  - dart-code.flutter 3.140.0
- Node.js: v24.19.0
- npm: 11.17.0

## Flutter Doctor

Final relevant status:

- Flutter SDK: installed and stable.
- Android toolchain: healthy.
- Android licenses: all accepted.
- Connected Android physical devices: none detected.
- Existing Android emulator: Light_Phone_API_35.
- Flutter detected the emulator as: sdk gphone64 x86 64, Android 15 API 35.
- Visual Studio for Windows desktop apps: not installed. This is not required for FLEXWOLF Android/iOS mobile development.

The current automation shell still reports Flutter/Dart PATH warnings because it inherited an old PATH. The user PATH has been updated with:

```text
D:\develop\flutter-stable\flutter\bin
```

Open a new terminal before using plain `flutter` or `dart`.

## Verification Results

- `flutter create --platforms=android,ios --org com.flexwolf --project-name flexwolf .`: passed.
- `flutter analyze`: passed, no issues found.
- `flutter test`: passed.
- `flutter build apk --debug`: passed.
- Debug APK path: build\app\outputs\flutter-apk\app-debug.apk
- Emulator launch: passed.
- `adb devices`: detected emulator-5554.
- `flutter devices`: detected Android emulator.
- Debug APK installation to emulator: passed with ADB streamed install.

## Git Status

- Local Git repository initialized.
- No remote repository configured.
- No GitHub repository was created.
- No code was pushed.

Required pending handover item:

```text
PENDING - CLIENT WILL PROVIDE FLEXWOLF REPOSITORY ACCESS LATER
```

## iOS Build Status

This machine is Windows.

IOS BUILD STATUS: Requires macOS + Xcode later.

The Flutter project has iOS scaffold files so the architecture remains cross-platform, but final iOS builds, signing, simulator testing, and App Store release work must be performed later on macOS with Xcode.

## Existing Flutter SDK Note

An existing Flutter checkout was found at:

```text
D:\develop\flutter
```

It is on the stable branch but is not usable for production setup in its current state. Its Flutter tool bootstrap failed, and its Git working tree showed extensive deleted SDK files. It was left untouched. The clean SDK used for this project is:

```text
D:\develop\flutter-stable\flutter
```
