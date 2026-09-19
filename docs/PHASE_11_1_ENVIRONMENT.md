# Phase 11.1 Production Environment Foundation

The app has explicit entry points for development, staging, and production:
- lib/main_development.dart
- lib/main_staging.dart
- lib/main_production.dart

Each entry point selects an isolated AppEnvironment. Defaults are safe placeholders until FLEXWOLF-owned endpoints and projects are supplied.

## Build-time configuration

Use Flutter compile-time defines. The checked-in .env.example contains non-secret keys only. CI may convert an environment file into --dart-define-from-file, or pass defines directly:

    flutter run -t lib/main_development.dart --dart-define-from-file=.env
    flutter build apk --debug -t lib/main_staging.dart --dart-define-from-file=.env.staging
    flutter build apk --release -t lib/main_production.dart --dart-define-from-file=.env.production

Supported values are API_BASE_URL, SHOPIFY_STORE_DOMAIN, FIREBASE_PROJECT_ID, DEEP_LINK_SCHEME, DEEP_LINK_HOST, APP_VERSION, BUILD_NUMBER, and RELEASE_NOTES. Do not place access tokens, private keys, Admin API credentials, Firebase service-account data, or provider secrets in these files.

The runtime exposes immutable AppConfig values for backend URL, Shopify store domain, Firebase project identity, deep-link configuration, and release metadata. No startup network request is required to load configuration.

## Firebase and Shopify

Firebase project selection is represented by the compile-time project ID. Dev, staging, and production project IDs and platform registration files remain CLIENT DEPENDENCY until FLEXWOLF supplies the approved Firebase projects and FlutterFire configuration.

Shopify Storefront and Customer Account configuration is environment-scoped. Shopify Admin API credentials are never accepted by the Flutter app and must remain server-side.

## Release configuration

pubspec.yaml remains the version fallback (1.0.0+1); APP_VERSION and BUILD_NUMBER can override it in CI. Release notes are metadata supplied by RELEASE_NOTES.

Android release signing reads ignored android/key.properties only when present. The repository contains no signing keys. A production release build must be signed by CI or the client-owned local keystore; debug builds remain available without release credentials. iOS uses Flutter's generated build name/number and requires client-owned Apple signing configuration on macOS/Xcode.

## Client dependencies

- FLEXWOLF-owned API base URLs and approved dev/staging/production environments.
- Firebase projects, Android/iOS registrations, and approved production configuration.
- Shopify store domain, Storefront public configuration, Customer Account client configuration, and protected-data approvals.
- Deep-link host/domain ownership and Android App Links/iOS Universal Links association files.
- Client-owned Android signing, Apple Developer team, bundle identifiers, and release approvals.
- CI secret management for any future server-side credentials.

No Phase 11 Chunk 2 work is included.
