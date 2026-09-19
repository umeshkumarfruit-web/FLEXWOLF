# Shopify API Version Policy

Verified against official Shopify documentation on 2026-08-31.

Selected stable versions:

- Storefront API: `2026-07`
- Customer Account API: `2026-07`
- Admin GraphQL API: `2026-07` if future backend-only use is genuinely required

Use explicit version pinning for production code instead of relying on `latest`
at runtime. Customer Account discovery endpoints may return versioned endpoint
URLs; use the discovered URL directly unless an approved requirement needs fixed
version construction.

## Why These Versions

`2026-07` is the current latest stable Shopify API version available in the
official API selectors during this checkpoint. Release-candidate/unstable APIs
are not selected for production foundation work.

## Review Policy

Review Shopify API versions and changelog at least quarterly, before each major
release, and before enabling new Shopify scopes or protected customer data.

Track:

- Storefront API cart/checkout changes
- Customer Account API auth/discovery changes
- Checkout Kit SDK changes
- Protected customer data requirements
- Metafield/metaobject Storefront visibility changes
- Deprecated checkout/customer account features

## Deprecation Findings

- Legacy customer accounts are deprecated; use Customer Account API for custom storefront/mobile customer data.
- `storefrontCustomerAccessTokenCreate` is deprecated; use Customer Account API OAuth access tokens directly where supported.
- Checkout metafields in checkout/customer account UI extensions were removed as of 2026-04; use cart/order metafield approaches where applicable later.
- Checkout Profile API / Checkout Branding API are replaced by Checkout And Accounts Configuration API for applicable Shopify Plus branding workflows.
- Do not rely on legacy checkout/customer account behavior.
