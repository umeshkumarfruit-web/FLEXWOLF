# Shopify Protected Customer Data

Verified against official Shopify protected customer data documentation on
2026-08-31. Request only the minimum customer data needed for approved features.

Statuses: REQUIRED, NOT REQUIRED, APPROVAL REQUIRED, AVAILABLE,
PENDING CLIENT/SHOPIFY APPROVAL.

| Field/Data | Future Use | Status | Notes |
| --- | --- | --- | --- |
| Name | Account profile, order display, checkout personalization | APPROVAL REQUIRED | Level 2 protected field when used through covered APIs. |
| Email | Login/account profile, order communication, marketing consent | APPROVAL REQUIRED | Level 2 protected field. |
| Phone | Account profile, delivery/contact, marketing consent where applicable | APPROVAL REQUIRED | Level 2 protected field. |
| Addresses | Address book, checkout/account profile | APPROVAL REQUIRED | Protected customer field/data. |
| Orders | Order history, tracking, returns | APPROVAL REQUIRED | Customer-scoped order data. |
| Customer ID | Identity linkage across app services | APPROVAL REQUIRED | Customer-scoped data; minimize exposure. |
| Marketing preferences | Klaviyo/customer preference alignment | APPROVAL REQUIRED | Consent-sensitive data. |
| Notification preferences | Push/email/SMS preference controls | APPROVAL REQUIRED | Consent-sensitive data. |
| Product/catalog data | Shop/PDP/collections | NOT REQUIRED | Not customer data by itself. |

Distribution type and app setup can affect approval requirements. FLEXWOLF and
Shopify approval must be confirmed before reading protected fields in production.
