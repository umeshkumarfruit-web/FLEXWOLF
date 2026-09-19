# Shopify Scope Tracking Register

No Shopify APIs are implemented in Phase 2. This document preserves scope and
security requirements for later integration work.

## Storefront API

| Area | Status | Notes |
| --- | --- | --- |
| Products | PLANNED | Shopify remains source of truth. |
| Variants | PLANNED | Include size/color/SKU mapping later. |
| Inventory | PLANNED | Read availability from Shopify; do not duplicate. |
| Collections | PLANNED | Shopify collections/metafields/metaobjects later. |
| Cart | PLANNED | Storefront cart flow later; no fake cart now. |

## Customer Account API

| Area | Status | Notes |
| --- | --- | --- |
| Login | NOT STARTED | Requires approved customer account approach. |
| Profile | NOT STARTED | Requires customer data approval review. |
| Addresses | NOT STARTED | Requires protected customer data handling. |
| Order history | NOT STARTED | Requires customer account compatibility planning. |
| Existing flexwolf.co customers | CLIENT ACCESS REQUIRED | Must confirm Shopify customer account mode. |

## Checkout

| Area | Status | Notes |
| --- | --- | --- |
| Shopify Checkout | PLANNED | Use Shopify-supported checkout flow. |
| Checkout Kit/current supported approach | PLANNED | Verify current supported mobile approach in later phase. |
| Guest checkout | PLANNED | Requires checkout configuration review. |
| Shop Pay | PLANNED | Depends on Shopify/payment setup. |
| Apple Pay | PLANNED | Requires Apple/Shopify/payment readiness. |
| Google Pay | PLANNED | Requires Google/Shopify/payment readiness. |
| Cards | PLANNED | Through Shopify-supported checkout. |
| PayPal | PLANNED | If enabled in Shopify. |
| Local payment methods | PLANNED | Where Shopify supports. |
| Discounts | PLANNED | Source from Shopify discount rules. |
| Bundles | PLANNED | Verify Shopify bundle/source-of-truth approach. |
| Shipping | PLANNED | Shopify checkout/shipping rates. |
| Taxes | PLANNED | Shopify tax configuration. |
| Duties | PLANNED | Shopify Markets/duties configuration. |
| Shopify Markets | PLANNED | International readiness later. |
| Gift cards/store credit | PLANNED | Where Shopify supports. |

## Admin API

| Area | Status | Notes |
| --- | --- | --- |
| Server-side only | PLANNED | Flutter must never call Admin API directly. |
| Genuine requirement review | NOT REQUIRED YET | Add only for secure backend needs. |

## Security

| Area | Status | Notes |
| --- | --- | --- |
| Minimum scopes | PLANNED | Scope-by-scope reason required before access. |
| Reason for every scope | PLANNED | Document before app/API setup. |
| FLEXWOLF approval | CLIENT ACCESS REQUIRED | Approval required for platform access. |
| Protected Customer Data approval | CLIENT ACCESS REQUIRED | Required if applicable to customer/order access. |
| No Admin secret/private key in app | PLANNED | Enforced by architecture boundary. |
