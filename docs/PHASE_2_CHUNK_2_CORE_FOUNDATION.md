# Phase 2 Chunk 2 Core Foundation

## Dependency Policy

No new packages were added in this chunk. Chunk 1 dependencies remain:

- `flutter_riverpod`: selected for scoped dependency injection, testable state,
  and avoiding widget-context coupling.
- `go_router`: selected for centralized routing, nested route readiness, and
  future deep-link/auth navigation support.
- `cupertino_icons`: retained from Flutter template for platform icon support.

Packages for Shopify, Firebase, Klaviyo, connectivity, secure storage, image
caching, and analytics are intentionally deferred until concrete implementation
requires them.

## Error Foundation

`AppException` now classifies errors by kind: network, timeout, authentication,
API, validation, unavailable, checkout, and unexpected. User-facing messages are
mapped centrally so raw technical exceptions are not shown directly.

## Network Foundation

`ApiClient`, `ApiRequest`, `ApiResponse`, and `CancellationToken` provide a future
request boundary for Shopify Storefront, Customer Account, and FLEXWOLF backend
calls. The default implementation makes no real calls and fails safely until a
concrete client is added.

## Logging Foundation

`AppLogger` is environment-aware. Development and staging can emit useful debug
messages. Production avoids verbose logs. Logs should never contain passwords,
access tokens, private API keys, payment details, or sensitive customer data.
Crashlytics can later be attached behind this boundary.

## Storage Foundation

`SecureStorage` is an abstraction for future Android Keystore/iOS Keychain-backed
storage. Current in-memory implementation is only a placeholder.

`LocalStorage` is an abstraction for non-sensitive preferences, recently viewed
references, safe cached settings, and onboarding state. Full ecommerce caching is
deferred.

## Connectivity And Weak Network

`ConnectivityService` and `ConnectivitySnapshot` define future weak-network
handling without inventing fake offline Shopify behavior. Later work can add
retry policies, stale-content preservation, cart resilience, and wishlist
resilience.

## Theme And Design Tokens

Initial design tokens cover temporary unverified colors, typography, spacing,
radii, icon sizes, button sizing, durations, and breakpoints. Final brand colors,
fonts, and visual details require FLEXWOLF approval/reference verification.

The startup shell demonstrates a native mobile structure, not a website copy or
WebView.

## Accessibility And Responsiveness

Reusable widgets use semantic labels/live regions where relevant, preserve system
text scaling, and use touch-target-friendly button sizing. `ResponsivePagePadding`
keeps layout adaptable across small and common phone sizes.

## Lifecycle, Deep Links, Navigation

`AppLifecycleObserver` records lifecycle transitions through the logger. GoRouter
contains placeholder routes for Home, Shop, Search, Wishlist, and Account. The
deep-link contract documents future product, collection, drop, offer, wishlist,
account, and order destinations without configuring production domains.

## Privacy And Customer Data Rules

- Collect only necessary customer data.
- Do not keep personal developer copies of customer data.
- Do not share customer data with unapproved third parties.
- Do not use customer data for training or testing unrelated products/models.
- Keep confidential FLEXWOLF business information confidential.
- Perform project-end customer-data cleanup where applicable.

Future work must cover Privacy Policy, Terms, marketing consent, notification
consent, analytics consent, ATT where required, account deletion, data controls,
App Store privacy disclosures, Google Data Safety, and iOS privacy manifests.

## Future Documentation Structure

Future docs should be completed for:

- dependencies/licenses
- API architecture
- Shopify configuration
- Firebase configuration
- backend
- environment variables and secret locations without exposing secrets
- builds/releases
- admin/CMS
- CI/CD
- version tagging
- backup/recovery
- third-party costs
- maintenance/handover
