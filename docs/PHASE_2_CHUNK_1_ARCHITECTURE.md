# FLEXWOLF Phase 2 Chunk 1 Architecture

## Scope

This chunk creates the real production Flutter project foundation for `flexwolf`.
It does not implement ecommerce features, Shopify calls, Firebase, Klaviyo,
checkout, app signing, publishing, PostgreSQL, or a production Node backend.

## GitHub Remote Status

GITHUB REMOTE STATUS: DEFERRED BY CLIENT

The project remains safe locally. No unofficial remote should be created or
pushed. The final codebase must be transferred to a FLEXWOLF-controlled
repository near final handover when client access is provided.

## Identifiers

Current generated development identifiers:

- Android namespace/applicationId: `com.flexwolf.flexwolf`
- iOS bundle identifier: `com.flexwolf.flexwolf`

CLIENT APPROVAL REQUIRED:

- Final Android application ID
- Final iOS bundle identifier

Identifier changes must be completed carefully before Firebase, deep links,
app signing, App Store Connect, Google Play Console setup, and production
release work.

## State Management

Selected: Riverpod (`flutter_riverpod`).

Reason: Riverpod is mature, testable, works without widget context coupling, and
supports scoped overrides for environment-specific bootstrap. Phase 2 only adds
minimal providers for configuration, routing, and core service boundaries.

## Routing

Selected: GoRouter.

Reason: GoRouter is a production-suitable declarative router that supports
nested navigation, authenticated/guest redirects, and deep links for future
product, collection, wishlist, notification, drop, and campaign destinations.
Only the root route is implemented in this chunk.

## Environment Strategy

The app has environment-aware Dart entry points:

- `lib/main_development.dart`
- `lib/main_staging.dart`
- `lib/main_production.dart`

`lib/main.dart` defaults to development for local runs. Shared Dart code remains
shared. Environment configuration is typed through `AppConfig`.

Development and staging have `allowsProductionSideEffects = false` so future
live-order, live-customer, Klaviyo production event, and production backend
operations can be guarded.

## Source Of Truth

Shopify remains the primary ecommerce backend/source of truth for:

- products
- titles/descriptions
- media
- variants
- sizes/colors
- SKUs
- collections
- inventory
- pricing
- compare-at pricing
- discounts
- tags
- metafields
- metaobjects
- customers
- orders
- fulfillment
- tracking

FLEXWOLF should not create a duplicate local ecommerce database for Shopify
product, customer, order, pricing, inventory, or fulfillment data.

## Shopify Integration Boundaries

Prepared future boundaries:

- Storefront API
- Customer Account API
- Checkout
- server-side Admin API functionality only when genuinely required

Admin API rule:

```text
Flutter App
  -> Secure backend
  -> Shopify Admin API
```

Never:

```text
Flutter App
  -> Shopify Admin API directly
```

## Backend And PostgreSQL

No production Node.js backend is built in this chunk. A future backend may handle
secure server-side Shopify Admin operations, webhooks, scheduled jobs, custom
CMS/business logic, notification processing, and secure integrations.

PostgreSQL is not installed or created in Phase 2 Chunk 1. If added later, it
may store only approved custom backend/app-specific data and must not duplicate
Shopify product, customer, order, pricing, inventory, or fulfillment records.

## Secret Management

No real secrets belong in Flutter source code. The `.gitignore` protects common
local and secret files including `.env`, signing keystores, provisioning files,
service-account JSON, `local.properties`, and Android key properties.

Files that need future handling decisions:

- `android/local.properties`: local machine path file, ignored
- `android/key.properties`: Android release signing file, ignored
- `ios/Flutter/Generated.xcconfig`: generated local build file, ignored
- Firebase generated config: deferred until official Firebase setup

Client platform access should use collaborator invites, developer invites,
role-based access, or official team access. Client passwords should not be sent
through chat.
