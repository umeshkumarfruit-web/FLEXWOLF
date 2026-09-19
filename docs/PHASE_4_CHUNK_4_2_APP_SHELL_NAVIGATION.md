# Phase 4 Chunk 4.2 - App Shell, Navigation, and Launch Foundation

Status: PARTIAL

This chunk creates the native FLEXWOLF app shell and main navigation foundation. It does not implement onboarding, Dynamic Home, Shop browsing, Product Detail, Cart, Checkout, Customer Account, Firebase, Klaviyo, Admin/CMS, or Phase 5 work.

## Verified Prior Work

- Phase 1 environment and architecture documentation remain present.
- Phase 2 app bootstrap, Riverpod, GoRouter, environment config, logging/storage/network boundaries remain present.
- Phase 3 Shopify Storefront, Customer Account, Checkout, and Admin API boundary files remain present and were not replaced.
- Phase 4 Chunk 4.1 design tokens, theme, responsive helpers, reusable components, tests, and documentation remain present.

## Brand Source

Primary visual reference: `https://flexwolf.co`.

The app shell continues the Chunk 4.1 direction: black/white/neutral colors, bold FLEXWOLF wordmark treatment, compact commerce navigation, restrained UI motion, and native Flutter components rather than WebView.

## App Shell

Primary implementation files:

- `lib/features/home/app_shell.dart`
- `lib/features/home/app_section.dart`
- `lib/features/home/app_destination_shell.dart`
- `lib/features/home/app_main_navigation_bar.dart`
- `lib/app/router/app_router.dart`

The shell uses `StatefulShellRoute.indexedStack` from GoRouter for top-level destinations. This preserves destination state, avoids duplicate top-level stacks, and keeps route definitions compatible with later nested flows.

## Navigation Structure

Top-level destinations:

- Home: `/`
- Shop: `/shop`
- Search: `/search`
- Wishlist: `/wishlist`
- Account: `/account`

All five routes currently render safe foundation placeholders only. The placeholders are explicit boundaries and do not implement later feature scope.

## Android Back Behavior

The shell uses `PopScope`:

- On Home, Android back can leave the app.
- On any other top-level destination, Android back returns to Home instead of creating confusing duplicate stacks.

Nested route behavior can be extended later inside individual shell branches.

## Header

The shell uses the Chunk 4.1 `FlexwolfHeader`, `FlexwolfLogo`, `AppIconActionButton`, and `EnvironmentLabel` components.

Current header actions:

- FLEXWOLF wordmark/title
- Search action that routes to the Search shell
- Environment label in non-production builds

Approved production logo asset is still missing, so the text wordmark remains a development-safe native placeholder.

## Splash / Launch

Existing platform launch files were inspected:

- Android: `android/app/src/main/res/drawable/launch_background.xml`
- Android styles: `android/app/src/main/res/values/styles.xml` and `values-night/styles.xml`
- iOS: `ios/Runner/Base.lproj/LaunchScreen.storyboard`

No approved production launch logo/splash image asset was found. Current launch remains minimal and fast, with no artificial delay and no startup network request.

CLIENT DEPENDENCY: approved launch logo/splash assets if FLEXWOLF requires branded native splash imagery.

## Route Transition Foundation

Top-level shell pages use restrained fade transitions backed by Chunk 4.1 motion tokens:

- `AppDurations.fast`
- `AppCurves.standard`

No flashy or long transitions were added.

## Accessibility Decisions

- Main navigation uses native `NavigationBar` semantics.
- Destination labels remain visible and semantic.
- Selected/unselected states use native selected icons plus selected semantics.
- Header search action has an explicit semantic label.
- Touch targets come from Material navigation/header controls and Chunk 4.1 component constraints.
- Destination placeholders use route semantics for logical screen-reader context.

## Deep-Link Readiness

The route paths and names remain centralized. `StatefulShellRoute.indexedStack` supports future nested routes for product, collection, promotion, notification target, account, order, and checkout flows without requiring fake links now.

## Shopify Compatibility

No Shopify data model or integration boundary was changed. The Flutter app still does not call Shopify Admin API directly and does not duplicate Shopify data in a new database.

## Testing

Added `test/app_shell_navigation_test.dart` covering:

- five top-level destination definitions
- header/navigation rendering
- destination switching
- header search action
- narrow mobile navigation rendering

Existing Phase 1-4.1 tests remain preserved.

## Known Limitations

- iOS was not built or run on this Windows machine. CLIENT/ENVIRONMENT VERIFICATION REQUIRED on macOS/Xcode.
- Final production logo and launch assets are not available in the repo.
- Destination screens remain placeholders by design until later Phase 4 chunks.
