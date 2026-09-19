# Shopify API Architecture

Verified against official Shopify documentation on 2026-08-31.

Selected stable versions:

- SHOPIFY_STOREFRONT_API_VERSION: `2026-07`
- CUSTOMER_ACCOUNT_API_VERSION: `2026-07`
- ADMIN_API_VERSION: `2026-07` if later genuinely required server-side

Official references:

- Storefront API: https://shopify.dev/docs/api/storefront/latest
- Customer Account API: https://shopify.dev/docs/api/customer/latest
- Admin GraphQL API: https://shopify.dev/docs/api/admin-graphql/latest
- Shopify API versioning: https://shopify.dev/docs/api/usage/versioning
- Mobile storefronts / Checkout Kit: https://shopify.dev/docs/storefronts/mobile/about-mobile-storefronts
- Protected customer data: https://shopify.dev/docs/apps/launch/protected-customer-data

## Mobile Architecture

```text
Flutter App
  |-- Shopify Storefront API
  |-- Shopify Customer Account API
  |-- Shopify Checkout / Checkout Kit bridge later
  |-- Firebase Functions secure backend when server-side operations are needed
        |-- Shopify Admin API only if genuinely required
```

Never:

```text
Flutter App
  -> Shopify Admin API private credentials
```

## Shopify Source Of Truth

Shopify remains the primary ecommerce backend/source of truth for products,
product titles, descriptions, images, videos, variants, sizes, colors, SKUs,
collections, inventory, pricing, compare-at pricing, discounts, tags,
metafields, metaobjects, customers, orders, fulfillment, and tracking.

The app must not manually duplicate ecommerce records. Shopify changes must
ultimately reach the app through Storefront/Customer APIs, webhooks, backend
sync, CMS rules, or remote config where appropriate.

## Storefront Authentication

Current Shopify Storefront API supports tokenless access and token-based access.
Tokenless access covers essential products/collections/search/cart operations
with Shopify's documented complexity constraints. Public Storefront tokens are
mobile/browser-safe for operations that require token-based public access.
Private Storefront tokens are server-only and must not be embedded in Flutter.

## Tokenless vs Public Token

| Operation | Auth Mode | Notes |
| --- | --- | --- |
| Products | TOKENLESS | Basic product browsing. |
| Collections | TOKENLESS | Basic collection browsing. |
| Search | TOKENLESS | Storefront search data. |
| Cart read/write | TOKENLESS | Mutations must not be silently retried. |
| Product tags | PUBLIC STOREFRONT TOKEN | Token-based public access required. |
| Metafields | PUBLIC STOREFRONT TOKEN | Requires configuration/permissions. |
| Metaobjects | PUBLIC STOREFRONT TOKEN | Requires configuration/permissions. |
| Menus/navigation | PUBLIC STOREFRONT TOKEN | If app uses Shopify navigation. |

## Customer Account API

Customer Account API authenticates buyers, not apps. Public mobile clients use
OAuth/OIDC authorization code flow with PKCE. The app must use discovery
endpoints rather than hardcoding fragile endpoints:

- `GET /.well-known/openid-configuration`
- `GET /.well-known/customer-account-api`

The discovered Customer Account GraphQL endpoint already includes the current
API version. If a fixed version is needed, use the selected stable `2026-07`.

Customer tokens are customer credentials and must use platform-secure storage:
Android Keystore-backed storage and iOS Keychain-backed storage. Never store
customer passwords or log tokens.

## Checkout Kit

Mobile storefront architecture uses Storefront API to build/manage cart and get a
`checkoutUrl`; Checkout Kit later presents Shopify checkout. Offsite payments and
return-to-app behavior require custom domain, Universal Links/App Links, Apple
app ID, Android application ID, and SHA-256 fingerprint configuration.

No Checkout Kit bridge is implemented in Phase 3 Chunk 1.

## Environment Separation

Development and staging must use non-production Shopify stores/configuration or
safe test setup. They must not create live customer/order pollution in the
production store. Production-side effects remain guarded by environment config.

SHOPIFY CLIENT ACCESS: CLIENT ACTION REQUIRED


