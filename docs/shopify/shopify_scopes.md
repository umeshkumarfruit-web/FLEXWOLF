# Shopify Scopes Register

Statuses: PROPOSED, CLIENT APPROVAL REQUIRED, APPROVED, NOT REQUIRED, REMOVED.

Minimum-scope principle: do not request broad scopes just in case. Every scope
must map to an approved feature and environment.

| API | Scope/Permission | Feature | Exact Reason | Customer Data? | Protected Data Approval? | Environment | Status | FLEXWOLF Approval |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Storefront API | tokenless access | Products, collections, search, cart | Basic public storefront operations supported without token | No for product/catalog; cart may be buyer-scoped later | No for basic catalog | Dev/Staging/Prod | PROPOSED | CLIENT APPROVAL REQUIRED |
| Storefront API | Public Storefront access token | Product tags, metafields, metaobjects, menus/navigation | Required by Shopify for these token-based public Storefront features | Potentially if customer operations later use Storefront customer fields | Depends on data used | Dev/Staging/Prod | PROPOSED | CLIENT APPROVAL REQUIRED |
| Customer Account API | customer_read_customers | Profile, email, phone, addresses, order history | Read authenticated buyer account data tied to Shopify identity | Yes | APPROVAL REQUIRED for customer fields | Dev/Staging/Prod | PROPOSED | CLIENT APPROVAL REQUIRED |
| Customer Account API | customer_write_customers | Profile/address updates, preferences where supported | Update buyer-managed customer/account data | Yes | APPROVAL REQUIRED for customer fields | Dev/Staging/Prod | PROPOSED | CLIENT APPROVAL REQUIRED |
| Admin GraphQL API | Admin scopes TBD | Server-side operations only if Storefront/Customer APIs cannot satisfy requirement | Not approved for Flutter; future backend only | Maybe | Depends on approved use | Backend only | NOT REQUIRED | CLIENT APPROVAL REQUIRED |
| Checkout Kit / Accelerated checkout | write_cart_wallet_payments | Future Apple Pay accelerated checkout | Required by Shopify docs for accelerated checkout Apple Pay support | Checkout/payment context | To be reviewed | iOS later | NOT REQUIRED | CLIENT APPROVAL REQUIRED |

No Shopify Admin secret/private key may be stored in Flutter source or mobile
runtime configuration.
