# Phase 12.5 Final Client Handover

## Delivery Scope

FLEXWOLF is ready for client handover at the Flutter repository level. This document summarizes source, configuration, build, ownership, and operational material required for delivery. It does not publish the app and does not add new product features.

Implemented app modules covered by handover:

- Authentication and guest mode
- Home and dynamic CMS-backed content boundary
- Shop, collections, search, filters, product details, variants, cart, checkout, orders, tracking, returns, reviews, wishlist, and support
- Notifications, deep links, admin portal, and CMS foundation
- Shopify, Firebase, Klaviyo, Gorgias, Redo, and reviews integration boundaries

## Source Code Handover

Flutter source code is contained in the repository root and uses the existing Flutter architecture:

- `lib/app`: app bootstrap, config, routing, theme, shell
- `lib/core`: shared storage, networking, security, logging, widgets, connectivity, lifecycle, media, privacy
- `lib/features`: feature modules and presentation/data/domain boundaries
- `lib/integrations`: external service boundaries for Shopify, Firebase, Klaviyo, Gorgias, Redo, analytics, CMS, and backend
- `test`: regression, QA, security, release, and phase validation tests
- `android` and `ios`: platform release preparation
- `.github/workflows`: CI/CD quality, Android build, and iOS preparation workflows
- `tools`: release build helper scripts

Backend source code is not present in this Flutter repository. Secret-bearing operations, Shopify Admin API calls, provider private-token use, webhook verification, and admin write operations must be implemented only in a secure client-owned backend.

## Installation Guide

1. Install Flutter from the stable channel and verify with `flutter doctor`.
2. Install Android Studio, Android SDK, and a compatible JDK/Gradle setup.
3. Run `flutter pub get` from the repository root.
4. Use `.env.example` as the non-secret environment template.
5. Do not commit `.env`, signing files, Firebase app files, service accounts, provisioning profiles, or provider credentials.
6. Run `flutter analyze` and `flutter test` before release builds.

## Configuration Guide

Environment values are centralized through `AppConfig` and the platform build configuration. Version and build number are centralized in `pubspec.yaml` as `version: 1.0.0+1`.

Required client-supplied configuration:

- Production API base URL
- Shopify production store domain and Storefront access
- Shopify Customer Account OAuth/PKCE redirect configuration
- Firebase production Android/iOS app files
- Deep-link host ownership files for Android and iOS
- Android signing configuration supplied outside git
- Apple Developer signing/provisioning supplied on macOS/Xcode
- Provider credentials for Klaviyo, Gorgias, Redo, and reviews platform through secure backend or approved provider flow

## Deployment Guide

Android release commands:

- `flutter build apk --release`
- `flutter build appbundle`

Android release output:

- APK: `build/app/outputs/flutter-apk/app-release.apk`
- AAB: `build/app/outputs/bundle/release/app-release.aab`

CI/CD workflows are prepared for quality checks and Android artifact generation. iOS workflow preparation exists, but signed archive/TestFlight/App Store delivery requires macOS, Xcode, Apple Developer credentials, provisioning profiles, APNs, and App Store Connect setup.

## Admin Guide

The admin portal and CMS foundation are present in the Flutter app. Live admin authentication, privileged writes, content publishing, support administration, marketing operations, and Shopify Admin API operations require a secure backend and client-approved roles. The Flutter app must never contain Shopify Admin API credentials, Firebase service accounts, provider private keys, or backend secrets.

## Client Guide

Client responsibilities before production publishing:

- Own the GitHub repository and branch protection settings.
- Own the Firebase production project and app credentials.
- Own Shopify production store, Customer Accounts, checkout, payment, shipping, tax, markets, and protected customer data approval.
- Own Klaviyo, Gorgias, Redo, and reviews platform accounts and credentials.
- Own Apple Developer and Google Play Console accounts.
- Supply privacy policy, terms URL, screenshots, store listings, age rating, compliance declarations, and release approvals.

## Troubleshooting Guide

- If Android signing fails, verify ignored `android/key.properties` and keystore paths in the client environment or CI secrets.
- If Firebase push fails, verify production Firebase app files, APNs, FCM token registration, notification permission, and payload deep links.
- If Shopify data does not load, verify production store domain, Storefront access, API version compatibility, and HTTPS endpoint policy.
- If checkout fails, verify Shopify checkout configuration, payment methods, markets, discounts, shipping, taxes, and redirect URLs.
- If deep links fail, verify Android Digital Asset Links and Apple App Site Association are published for the production host.
- If provider features stay in fallback mode, verify backend/provider credentials for Klaviyo, Gorgias, Redo, and reviews platform.
- If iOS release is blocked, run final build/sign/archive on macOS with Xcode and client Apple credentials.
