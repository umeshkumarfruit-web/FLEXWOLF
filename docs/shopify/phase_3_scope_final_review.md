# Shopify Phase 3 Scope Final Review

No live Shopify API access is implemented or tested in Phase 3. Do not request
future scopes prematurely; approve minimum scopes only when the related feature is
being implemented.

| API | Scope/Permission | Feature | Why Needed | Customer Data? | Protected Data? | Client Approval Status | Implemented? |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Storefront API | tokenless access | Basic products, collections, search, cart foundation | Supported for basic public storefront operations | No for catalog; cart buyer data later | No for basic catalog | Client approval required before live test | Architecture only |
| Storefront API | Public Storefront access token | Mobile storefront access via Headless channel | Required by current mobile storefront docs and for token-based public operations | Potentially later | Depends on fields | Client approval required | Header support only |
| Customer Account API | Customer read permissions | Profile, addresses, order history | Authenticated customer features tied to Shopify identity | Yes | Yes | Client/Shopify approval required | Architecture only |
| Customer Account API | Customer write permissions | Address/profile/preference updates where supported | Buyer-managed account updates | Yes | Yes | Client/Shopify approval required | Not implemented |
| Checkout Kit | Platform checkout configuration | Shopify-powered checkout | Present checkout URL in native sheet later | Checkout data | Payment handled by Shopify | Client approval required | Bridge contract only |
| Admin GraphQL API | TBD server-side scopes | Backend-only approved operations | Only if Storefront/Customer APIs cannot satisfy requirement | Maybe | Depends | Not required yet | Not implemented |

Removed unnecessary permissions: none were added to runtime configuration.
