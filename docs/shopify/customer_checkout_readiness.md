# Customer Account And Checkout Readiness

CUSTOMER ACCOUNT LIVE AUTH: STAGING VERIFICATION REQUIRED

The local `.env` has a Customer Account API client ID and redirect URI, but its
store domain points to the production FLEXWOLF store. No staging store config or
test customer details were found in the workspace. The public Storefront API
token is also missing locally. Do not create test customers or orders on the
production store. Verify the account flow with a staging config and device.

## Existing Customer Requirement

Existing flexwolf.co customers must use the same Shopify customer identity/account
architecture and see existing order history where Shopify supports it.

Do not create a duplicate local, PostgreSQL, MongoDB, or Firebase Auth replacement
for Shopify customer identity unless FLEXWOLF explicitly approves a future
architecture change.

## Current Auth Architecture

Use Shopify Customer Account API with OAuth/OIDC authorization code flow and PKCE
for public mobile clients. Use discovery endpoints:

- `/.well-known/openid-configuration`
- `/.well-known/customer-account-api`

Public mobile clients do not receive refresh tokens per current Shopify docs.
Silent renewal should repeat authorization with `prompt=none` while the Shopify
customer session is active. If Shopify returns `login_required`, start an
interactive authorization flow.

## Signup / Passwordless

Customer account creation and passwordless/one-time-code behavior must follow the
current Shopify customer account flow. Do not use obsolete Storefront customer
password mutations or build a custom OTP database.

## Logout / Session Restoration

Logout must call Shopify/customer authorization logout where configured, clear
secure token storage, and clear in-memory session state. It must not delete
unrelated non-sensitive customer preferences.

Startup restoration must handle valid session, expired access, silent renewal,
revoked session, and logout without plaintext token persistence.

## Checkout Architecture

Shopify powers checkout:

```text
Storefront cart checkoutUrl
  -> Shopify Checkout Kit native bridge where practical/currently supported
  OR approved Shopify-hosted checkout flow
```

Current Flutter checkout path:

```text
Android: Flutter -> MethodChannel -> Android native Checkout Kit
iOS: Flutter -> in-app Shopify hosted checkout browser view
```

Android native bridging is implemented and builds. iOS uses an in-app hosted
checkout browser view; a native iOS Checkout Kit bridge is not implemented.
Neither platform has been verified on a device with a staging payment.

## Checkout Callbacks

Checkout state handles completed, cancelled, failed/error, and closed. Closing
the checkout UI is not treated as a completed purchase. Confirm callbacks on a
device against the staging store before go-live.

## Payment Security

FLEXWOLF custom backend must never process or store card data. Do not create card
number fields, CVV storage, custom payment tokenization backend, or custom payment
processor replacing Shopify checkout.

## Payment Method Register

| Method | Status | Notes |
| --- | --- | --- |
| Shop Pay | CLIENT CONFIGURATION REQUIRED | Claim active only after Shopify config verification. |
| Apple Pay | CLIENT CONFIGURATION REQUIRED | Requires platform/merchant setup. |
| Google Pay | CLIENT CONFIGURATION REQUIRED | Through Shopify-supported checkout/payment setup. |
| Credit cards | CLIENT CONFIGURATION REQUIRED | Shopify checkout handles payment. |
| PayPal | CLIENT CONFIGURATION REQUIRED | Where enabled by merchant. |
| Shopify-supported accelerated/local methods | CLIENT CONFIGURATION REQUIRED | Verify per market/platform. |

Accelerated checkouts: official docs currently state accelerated checkout support
is available on iOS native Swift and React Native; Android accelerated checkout is
not supported yet. Checkout Kit itself supports Android and iOS.

## Guest Checkout

Guest checkout is mandatory. Architecture must never require signup before
browsing, login before cart, login before checkout, or forced account creation.
Preserve CONTINUE AS GUEST for later UX.

## Discounts, Bundles, Markets, Gift Cards

Shopify remains authority for percentage discounts, fixed discounts, quantity
discounts, bundles, free shipping, automatic discounts, promo codes, member
discounts, app-only discounts where backend enforcement exists, and stacking
rules.

Do not show client-side bundle discounts that Shopify checkout will not honor.
Shopify Markets checkout must preserve market, currency, pricing, shipping,
taxes, and duties. Gift cards/store credit must use Shopify-supported mechanisms
and not a duplicate wallet/balance database.
