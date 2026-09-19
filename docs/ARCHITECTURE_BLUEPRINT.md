# FLEXWOLF Production Architecture Blueprint

This is a Phase 1 blueprint only. It prepares the project for production development without implementing ecommerce features yet.

## Target Platforms

- Flutter mobile app for Android and iOS.
- Android development is available on this Windows machine.
- iOS builds require macOS and Xcode later.

## Application Layers

Recommended Flutter structure for future chunks:

```text
lib/
  app/
    app.dart
    router.dart
    theme/
  core/
    config/
    errors/
    network/
    storage/
    telemetry/
  features/
    auth/
    catalog/
    product/
    cart/
    checkout/
    account/
    orders/
    wishlist/
  integrations/
    shopify/
    firebase/
    klaviyo/
    backend/
  shared/
    widgets/
    models/
    utils/
```

## Environments

Prepare for three environments:

- Development
- Staging
- Production

Future implementation should use explicit environment configuration for:

- Shopify storefront domain
- Shopify Storefront API token
- Firebase project IDs and platform files
- Klaviyo public/company IDs
- Backend API base URL
- App flavor or build mode
- Logging/analytics level

Secrets must not be committed. Client-owned secrets should be supplied through secure handover channels and CI/CD secrets later.

## Shopify Readiness

The mobile app should use Shopify Storefront API for customer-facing commerce flows where suitable:

- Catalog browsing
- Product detail
- Product variants
- Cart
- Checkout handoff or native checkout strategy
- Customer account strategy, if approved

Admin API usage must not be exposed in the app. Any Admin API or secret-bearing operation must go through a secure backend.

## Firebase Readiness

Firebase may be added later for:

- Push notifications
- Analytics
- Crash reporting
- Remote Config
- Authentication only if it matches the final account strategy

Required later access:

- Firebase project access
- Android `google-services.json`
- iOS `GoogleService-Info.plist`
- Firebase Apple/Android app registrations

## Klaviyo Readiness

Klaviyo may be added later for:

- Event tracking
- Push or email/SMS attribution
- Customer lifecycle events

The app should not send sensitive secrets directly to Klaviyo. Server-side events that need private keys should route through the backend.

## Backend Readiness

A Node.js backend should only be introduced where genuinely required, such as:

- Secure Shopify Admin API operations
- Webhooks
- Payment or checkout orchestration not safely handled client-side
- Klaviyo private-key events
- Custom business rules
- App-specific secure data not owned by Shopify/Firebase

If custom persistent backend data is required, use PostgreSQL. Do not add PostgreSQL for data that Shopify or Firebase already owns cleanly.

## Source Control and Ownership

Local Git is enabled for development.

Production GitHub ownership is intentionally deferred:

```text
PENDING - CLIENT WILL PROVIDE FLEXWOLF REPOSITORY ACCESS LATER
```

No unofficial production GitHub repository should be created under a personal/developer account.

## Phase Boundaries

Chunk 1 establishes environment readiness, a minimal Flutter scaffold, and planning documents.

Do not treat Phase 1 as complete yet. Later Phase 1 chunks still need broader tooling/project planning, access inventory, and final Phase 2 readiness confirmation.
