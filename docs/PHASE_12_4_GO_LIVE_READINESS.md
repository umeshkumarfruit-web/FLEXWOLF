# Phase 12.4 Production Go-Live Readiness

## Production Readiness

FLEXWOLF is prepared for production go-live at the repository/configuration level. No production deployment or store publishing was performed.

- Production environment exists through `AppEnvironment.production` and `lib/main_production.dart`.
- Production config uses HTTPS backend defaults, disables diagnostics, disables verbose logging, and applies a 15 second network timeout.
- Version and build number remain centralized in `pubspec.yaml` as `1.0.0+1`.
- Android release APK and AAB builds are supported through Flutter and CI automation.
- iOS release preparation exists, but build/sign/archive requires macOS/Xcode and Apple credentials.

## Third-Party Readiness

- Shopify: App-side Storefront, Customer Account, checkout, product, collection, cart, order, and Admin API boundaries are prepared. Production store domain, Storefront access, Customer Account OAuth/PKCE, protected customer data approval, payment verification, and checkout bridge remain CLIENT DEPENDENCY.
- Firebase: Messaging, analytics, crash reporting, and Remote Config boundaries are prepared. Production Firebase apps, `google-services.json`, `GoogleService-Info.plist`, APNs, token sync, and Remote Config governance remain CLIENT DEPENDENCY.
- Klaviyo: Boundary is preserved for marketing/event integration. Credentials and event contract remain CLIENT DEPENDENCY.
- Gorgias: Support boundary is preserved. Secure ticket endpoint and credentials remain CLIENT DEPENDENCY.
- Redo: Returns boundary is preserved. API credentials and backend contract remain CLIENT DEPENDENCY.
- Reviews Platform: Provider-neutral review repository is prepared. Provider credentials, product mapping, media upload, and moderation integration remain CLIENT DEPENDENCY.

## Store Readiness

Android:

- Release APK: prepared and validated by Flutter release build.
- AAB: prepared and validated by Flutter app bundle build.
- App icon: present in Android mipmap folders.
- Splash: present through Android launch background resources.
- Deep links: custom scheme and verified HTTPS app links prepared.
- Signing keys: not committed; must be supplied through client-controlled signing.

IOS:

- Bundle identifier: `com.flexwolf.flexwolf`.
- Push capability: prepared in entitlements.
- Associated Domains: prepared for `applinks:flexwolf.com`.
- URL scheme: prepared for `flexwolf`.
- Release preparation: present, but macOS/Xcode and Apple credentials are required.

## Go-Live Checklist

Firebase Production:

- Create/confirm FLEXWOLF-owned Firebase production project.
- Add Android and iOS production apps.
- Supply `google-services.json` and `GoogleService-Info.plist` outside source control.
- Configure APNs for iOS push.
- Verify FCM token registration, foreground delivery, background delivery, notification open, Analytics, Crashlytics, and Remote Config values.

Shopify Production:

- Confirm production Shopify store domain.
- Configure Storefront access needed by app features.
- Configure Customer Account OAuth/PKCE and redirect URI.
- Confirm protected customer data approvals.
- Verify products, collections, variants, inventory, prices, discounts, markets, taxes, duties, shipping, and order history.

Notification Verification:

- Verify Android notification permission prompt.
- Verify iOS APNs permission and token registration.
- Verify push payload deep links for products, collections, wishlist, and orders.
- Verify invalid notification links fail safe.

Payment Verification:

- Verify Shopify checkout handoff or Checkout Kit bridge.
- Verify Shop Pay, Apple Pay, Google Pay, cards, PayPal, discounts, gift cards/store credit, shipping, taxes, and order confirmation in Shopify.

Deep Link Verification:

- Publish Android Digital Asset Links for `flexwolf.com`.
- Publish Apple App Site Association for `applinks:flexwolf.com`.
- Verify `/products/{handle}`, `/collections/{handle}`, `/account/orders/{id}`, and `/wishlist`.

Analytics Verification:

- Verify only approved app analytics events are emitted.
- Verify notification, deep-link, checkout, wishlist, product, review, support, and admin events in the selected analytics backend.

## Performance And Security

- Startup config is compile-time and does not require a boot network call.
- Network transport uses HTTPS validation, timeouts, retryable error classification, and safe error messages where concrete clients exist.
- Remote images reject non-HTTPS URLs and use Flutter image caching.
- Caches/coalescing exist for Home, Shop, reviews, admin operations, and checkout preparation.
- Secure storage boundaries exist for customer/admin sessions and notification registration.
- No signing keys, Firebase service accounts, Shopify Admin API tokens, provider secrets, or `.env` files are committed.
