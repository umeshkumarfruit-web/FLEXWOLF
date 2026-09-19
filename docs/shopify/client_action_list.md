# Shopify Phase 3 Client Actions

Do not send passwords. Use collaborator invitations, developer access, team roles,
and service-specific access.

## Needed Now

| Action | Purpose |
| --- | --- |
| Shopify collaborator/developer invite | Allow safe verification of store configuration. |
| Apps/channels permission | Configure/review Headless and custom app settings. |
| Headless channel setup/access | Obtain Storefront configuration and public token where required. |
| Storefront configuration | Verify read-only product/collection/cart schema access. |
| Customer Accounts configuration visibility | Confirm Customer Account API availability and existing customer compatibility. |
| Customer Account API client configuration | Prepare public client ID, OAuth/PKCE authorization, token, logout, and GraphQL endpoint discovery. |
| Scope approval | Approve minimum Customer Account read/write scopes only for profile and address management. |
| Protected customer data approval review | Required before profile, address, order history, and tracking features. |
| Confirmation of metafield/metaobject schemas | Avoid guessed namespace/key/schema usage. |

## Needed In Later Phase

| Action | Purpose |
| --- | --- |
| Approved redirect URLs | Required for Customer Account OAuth callback handling on Android App Links and iOS Universal Links. |
| Checkout configuration/access | Required for Shopify Checkout Kit or approved hosted checkout handoff testing. |
| Android App Links and iOS Universal Links setup | Required for auth callback restore and offsite payment return flows. |
| Shopify Markets configuration review | Required for countries, currencies, duties, taxes, and local pricing behavior. |
| Payment method verification | Confirm Shopify-hosted payment methods: Shop Pay, Apple Pay, Google Pay, cards, PayPal, and local methods. |
| Test customer/test order policy | Provide safe test orders with fulfillment/tracking coverage and avoid real customer/order pollution. |
| Backend secret manager setup | Required only if backend/Admin API is approved later. |





## Phase 7 Remaining Blockers

| Dependency | Purpose |
| --- | --- |
| Customer Account OAuth and GraphQL transport | Live auth, profile, addresses, orders, and tracking. |
| Protected customer data approval | Required for customer profile, address, and order fields. |
| Storefront Cart API mutations | Live cart buyer identity, discounts, gift cards, checkout URL refresh. |
| Checkout Kit or hosted checkout handoff | Production payment handoff without custom payment gateway. |
| Shopify Markets setup | Countries, currencies, local pricing, duties, and taxes. |
| Test customers and test orders | Safe validation without production customer/order pollution. |

| Wishlist persistence decision | Confirm Customer Account metafield/backend strategy for logged-in wishlist sync. |


| Firebase FCM setup | Provide FLEXWOLF-owned Firebase apps, platform files, APNs setup, and token registration endpoint. |

