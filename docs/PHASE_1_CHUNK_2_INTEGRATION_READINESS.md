# FLEXWOLF Phase 1 - Chunk 2 Integration Readiness

Status date: 2026-08-31

This document records Phase 1 Chunk 2 only. Phase 1 is not complete after this chunk.

## Shopify Architecture Readiness

Shopify integration is a core contract requirement and must not be dropped in later phases.

### Storefront API

Future Flutter responsibilities include:

- Products
- Product information
- Variants
- Sizes
- Colors
- Collections
- Pricing
- Compare-at pricing
- Inventory availability
- Cart functionality
- Shopify storefront data

The Storefront API should be the default client-facing commerce integration where Shopify officially supports mobile usage.

### Customer Account API

Future responsibilities include:

- Login
- Logout
- Customer profile
- Customer addresses
- Customer order history
- Existing FLEXWOLF website customer compatibility

Later phases must confirm the current FLEXWOLF website customer/account model before implementing app login.

### Checkout

Future responsibilities include:

- Shopify Checkout
- Checkout Kit where appropriate and currently supported
- Secure Shopify-hosted checkout if needed
- Guest checkout
- Discounts
- Bundles
- Shipping
- Taxes
- Duties
- Shopify Markets
- Supported payments

Checkout architecture must be confirmed against current Shopify mobile capabilities before implementation.

### Admin API

Rule:

```text
NEVER call Shopify Admin API directly from Flutter.
```

Shopify Admin API may only be used server-side and only when genuinely required.

Possible server-side uses:

- Secure Admin API operations
- Webhooks
- Private business rules
- Private data synchronization
- Operations requiring protected/private Shopify credentials

### Shopify Scopes

Future Shopify app setup must:

- Use minimum required scopes.
- Document every requested scope.
- Document why each scope is needed.
- Obtain FLEXWOLF approval where required.
- Avoid broad scopes that are not directly tied to approved functionality.

### Protected Customer Data

Later phases must verify whether Shopify protected customer data approval is required for planned customer account, order, and profile features.

### Shopify Security Rules

Never place these inside Flutter:

- Shopify client secret
- Shopify Admin access token
- Private API key
- Private signing secret

No real Shopify credentials are created or configured in Phase 1.

## Firebase Readiness

Firebase may later support:

- Firebase Analytics
- Firebase Cloud Messaging / FCM
- Crashlytics
- Remote Config
- Technical logging/configuration where applicable

Phase 1 does not create or configure the final production Firebase project, and does not place real production Firebase configuration into the temporary app.

Future Firebase setup must confirm:

- FLEXWOLF-owned Firebase project
- Android app registration
- iOS app registration
- `google-services.json`
- `GoogleService-Info.plist`
- Analytics event plan
- Push notification permissions and UX
- Crashlytics symbol/upload requirements
- Remote Config key ownership and rollout rules

## Klaviyo Readiness

Klaviyo may later support:

- Marketing profiles
- Marketing events
- Segmentation
- Marketing push functionality where required

Security rule:

- Mobile-safe/client configuration may be used in Flutter where officially supported.
- Private Klaviyo API credentials must remain server-side.

No real Klaviyo credentials are created or configured in Phase 1.

## Future Third-Party Readiness

Later phases may require access or configuration for:

- Klaviyo
- Firebase
- Redo returns/exchanges
- Current review platform
- Gorgias
- Meta
- Apple Developer
- Google Play Console
- Hosting/cloud
- CMS/admin platform
- Domain/deep links

These are not integrated in Phase 1.

## Dev / Staging / Production Strategy

The project must eventually maintain separate environments:

- Development
- Staging
- Production

Future architecture should support environment-specific:

- API base URLs
- Shopify configuration
- Backend URLs
- Firebase configuration where required
- Logging behavior
- Analytics behavior
- Feature configuration

Testing must not accidentally create or use live:

- Shopify customers
- Shopify orders
- Klaviyo production test data

No real production environment secrets are configured in Phase 1.

## Future Flutter Environment Configuration

Recommended Phase 2 direction:

- Use explicit environment entry points and/or Flutter build flavors for dev, staging, and production.
- Keep environment selection visible in build commands and CI/CD configuration.
- Keep production-only behavior disabled by default in local development.
- Use typed configuration objects inside Flutter rather than ad hoc string reads spread across features.
- Keep secret-bearing operations out of Flutter and behind secure backend endpoints.

Phase 1 does not implement full flavors in the temporary app. Phase 2 should implement the real environment architecture.

## Secret Management Strategy

Sensitive secrets must never be committed.

Examples:

- Shopify Admin API token
- Shopify client secret
- Webhook secrets
- Klaviyo private API key
- Database credentials
- Backend secrets
- Private keys
- Android signing secrets
- Apple signing credentials

Production secrets should eventually live in FLEXWOLF-controlled hosting/cloud secret management or environment configuration.

## Local Secret File Rules

Future project should protect local/sensitive files such as:

- `.env`
- `.env.*`
- `local.properties`
- Signing files
- Private credential files
- Keystores
- Service account files

Do not create production secrets in Phase 1. Do not place actual secrets in source control.

## GitHub Ownership

Required pending handover item:

```text
PENDING - CLIENT WILL PROVIDE FLEXWOLF REPOSITORY ACCESS LATER
```

No unofficial production GitHub repository should be created under a personal/developer account.
