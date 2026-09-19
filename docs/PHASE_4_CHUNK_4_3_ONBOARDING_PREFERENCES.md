# Phase 4 Chunk 4.3 - Onboarding, Guest Mode, Preferences

Status: COMPLETE for Phase 4 Chunk 4.3 recovery scope, with documented client dependencies.

This chunk implements the first-launch onboarding foundation, Continue as Guest entry path, local customer preference foundation, and personalization-ready interfaces. It does not implement Dynamic Home, Shop, Product Detail, Cart, Checkout, full Customer Account, Firebase production integration, recommendation engines, fake AI, duplicate customer databases, Chunk 4.4, or Phase 5.

## Verified Prior Work

- Phase 1 environment and planning docs remain present.
- Phase 2 app bootstrap, Riverpod, GoRouter, environment configuration, core storage, logging, and network boundaries remain present.
- Phase 3 Shopify Storefront, Customer Account, Checkout, and Admin API boundaries remain present and were not replaced.
- Phase 4 Chunk 4.1 design tokens/components remain the visual foundation.
- Phase 4 Chunk 4.2 `StatefulShellRoute.indexedStack` app shell and main navigation remain intact.

## Onboarding Flow

Primary implementation files:

- `lib/features/onboarding/presentation/onboarding_gate.dart`
- `lib/features/onboarding/data/onboarding_repository.dart`
- `lib/features/onboarding/data/onboarding_providers.dart`
- `lib/features/onboarding/domain/onboarding_snapshot.dart`

First launch shows a short native FLEXWOLF onboarding screen with:

- FLEXWOLF logo text treatment
- `WELCOME TO THE PACK`
- Choose preferences
- Continue as Guest
- Skip for now

The flow is responsive, scrollable, accessible, and uses Chunk 4.1 tokens/components.

## First-Launch Behavior

Onboarding state supports:

- first launch
- onboarding started
- skipped
- completed
- returning user

Returning users bypass onboarding and land in the existing app shell. There is no artificial startup delay and no onboarding network request.

## Continue as Guest

`Continue as Guest` persists local guest mode and enters the app shell. It does not create a Shopify customer, fake account, Firebase auth user, or duplicate customer record.

Guest mode remains compatible with future browse/search/product/cart/guest checkout flows, but checkout itself is not implemented in this chunk.

## Preference Model

Preference options are centralized domain data in `lib/features/onboarding/domain/preference_option.dart`.

Initial categories:

- Tees
- Tanks
- Shorts
- Sweats
- New Drops

Initial sizes:

- S
- M
- L
- XL
- XXL

These values are configurable through `PreferenceCatalog` and are not scattered as UI-only constants.

## Local Persistence

Persistence uses the existing `LocalStorage` abstraction.

Production/runtime bootstrap now supplies `SharedPreferencesLocalStorage`, backed by `shared_preferences`. Tests continue to use `InMemoryLocalStorage` overrides.

Stored data:

- onboarding status
- guest mode boolean
- selected category ids
- selected size ids

No PII, tokens, passwords, or customer auth credentials are stored by this chunk.

## Personalization-Ready Boundary

The local preference model can later feed approved personalization surfaces alongside permitted signals such as recently viewed, wishlist, browsing signals, and recommendation signals.

Not implemented:

- recommendation engine
- fake AI
- customer data sync
- duplicate customer database
- Shopify data duplication

Shopify remains ecommerce source of truth.

## Analytics Abstraction

Provider-neutral event names were added to `lib/integrations/analytics/analytics_boundary.dart` with a no-op gateway:

- `onboarding_started`
- `onboarding_completed`
- `onboarding_skipped`
- `guest_continue`
- `preference_selected`
- `preference_saved`

No Firebase project, Firebase credentials, or live analytics provider was added.

## Privacy Decisions

- Preferences are optional and skippable.
- Guests can use the app shell without account creation.
- No production customer data is accessed.
- No third-party sharing is added.
- No training/model usage is added.

## Accessibility Decisions

- Uses semantic labels from existing buttons/chips/logo components.
- Uses visible selected chip checkmarks, not color-only state.
- Uses SafeArea and scrollable layout.
- Maintains touch targets via Chunk 4.1 components.
- Supports text scaling within the existing app clamp.

## Tests

Added `test/onboarding_test.dart` covering:

- preference catalog data
- onboarding repository persistence
- first-launch rendering
- skip behavior
- Continue as Guest behavior
- preference selection/deselection/save
- returning-user bypass
- narrow mobile onboarding rendering

Existing app shell, design system, bootstrap, Shopify data, and customer checkout foundation tests are preserved.

## Client Dependencies

- Final onboarding copy approval.
- Approved FLEXWOLF logo asset if text wordmark is not final.
- Final preference taxonomy approval.
- Analytics provider approval before enabling live tracking.
- Future account sync rules if preferences should sync to authenticated customer profiles.
## Recovery Completion Note

Recovery review confirmed the Phase 4 Chunk 4.3 implementation is present after later chunk work: onboarding gate wiring, first-launch flow, Continue as Guest, local preferences, shared-preferences-backed runtime persistence, analytics abstraction, privacy boundaries, accessibility foundations, and tests. No completed Phase 4 Chunk 4 work was rebuilt or overwritten.

