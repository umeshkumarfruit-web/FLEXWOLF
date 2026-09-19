# FLEXWOLF Mobile App

FLEXWOLF is a custom Flutter ecommerce mobile app foundation for Android and iOS.
This repository is the production app codebase foundation, not a WebView wrapper
around `flexwolf.co`.

## Current Status

Phase 5 Chunk 5.2 establishes the Dynamic Home UI, section renderer registry, contract renderer coverage for all 22 Home section types, Shopify product/collection rail integration boundaries, Home action dispatching, loading/error/empty/stale states, and development-only renderer preview. CMS/admin controls remain deferred to Phase 5 Chunk 5.3.

GITHUB REMOTE STATUS: DEFERRED BY CLIENT

No unofficial remote should be created or pushed. The final project must be
connected to a FLEXWOLF-controlled GitHub repository near final handover when
client access is provided.

## Verified Tooling

- Flutter: 3.47.1 stable
- Dart: 3.13.1
- Android SDK: available from Phase 1 verification
- Java/JDK: available from Phase 1 verification
- Node/npm: available for future backend/tooling work

On Windows, iOS source folders can be maintained, but iOS builds require macOS
with Xcode and Apple Developer team access.

## Setup

```powershell
flutter pub get
flutter analyze
flutter test
```

Run development locally:

```powershell
flutter run -t lib/main_development.dart
```

Build Android development debug APK:

```powershell
flutter build apk --debug -t lib/main_development.dart
```

## Architecture

The app uses feature-oriented Flutter architecture:

- `lib/app`: bootstrap, environment config, router, theme
- `lib/core`: shared errors, network, logging, storage, layout, widgets, lifecycle
- `lib/features`: app feature areas
- `lib/integrations`: boundaries for Shopify, Firebase, Klaviyo, backend, CMS, analytics

State management: Riverpod.
Routing: GoRouter.

## Environment Strategy

Entry points:

- `lib/main_development.dart`
- `lib/main_staging.dart`
- `lib/main_production.dart`

Development and staging disable production side effects. Production-only actions
must pass explicit environment guards before future integrations are added.

## Dependency Approach

Prefer maintained, production-suitable packages and keep dependencies limited.
Current direct app dependencies:

- `flutter_riverpod`: state management and testable dependency overrides
- `go_router`: declarative routing and future deep-link/auth route support
- `cupertino_icons`: standard Flutter icon support

No Shopify, Firebase, Klaviyo, analytics, secure-storage, connectivity, or media
cache packages are added yet. Those should be added only when a later phase needs
real platform functionality.

## Secret Management

Do not commit secrets. Do not put private server credentials in the Flutter app.
The mobile app must never call Shopify Admin API directly.

Protected local/secret files include `.env`, signing keystores, provisioning
files, service-account JSON, `android/local.properties`, and `android/key.properties`.

## Future Integration Boundaries

- Shopify Storefront API
- Shopify Customer Account API
- Shopify Checkout
- Secure backend for Shopify Admin API operations
- Firebase Analytics, FCM, Crashlytics, Remote Config
- Klaviyo profile, segmentation, marketing push, and event tracking
- CMS/remote config for banners, promos, content, navigation, and toggles

No real CMS, Firebase, Klaviyo, backend, Shopify private, or production analytics credentials are configured in Phase 5 Chunk 5.1.
## Design System

Phase 4 Chunk 4.1 design-system foundation is documented in `docs/PHASE_4_CHUNK_4_1_DESIGN_SYSTEM.md`.

Core locations:

- `lib/core/design/design_tokens.dart`
- `lib/app/theme/app_theme.dart`
- `lib/core/layout/responsive_page_padding.dart`
- `lib/core/widgets/`

Final brand assets, exact font approval, and final visual approval remain client dependencies.

Phase 4 Chunk 4.2 app shell and navigation foundation is documented in `docs/PHASE_4_CHUNK_4_2_APP_SHELL_NAVIGATION.md`.

Phase 4 Chunk 4.3 onboarding, guest mode, and preferences foundation is documented in `docs/PHASE_4_CHUNK_4_3_ONBOARDING_PREFERENCES.md`.

Phase 4 final audit is documented in `docs/PHASE_4_FINAL_AUDIT.md`.

Phase 5 Chunk 5.1 Dynamic Home architecture is documented in `docs/PHASE_5_CHUNK_5_1_DYNAMIC_HOME_ARCHITECTURE.md`.

Phase 5 Chunk 5.2 Dynamic Home UI and renderers are documented in `docs/PHASE_5_CHUNK_5_2_DYNAMIC_HOME_UI.md`.








Phase 5 Chunk 5.3 Home hardening is documented in docs/PHASE_5_CHUNK_5_3_DYNAMIC_HOME_HARDENING.md.

