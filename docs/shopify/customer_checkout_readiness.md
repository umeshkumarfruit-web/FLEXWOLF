# Customer Account And Checkout Readiness

CUSTOMER ACCOUNT LIVE AUTH: CLIENT CONFIGURATION REQUIRED

No Customer Account API client configuration, redirect URI, test account, or
non-production authorization setup is available locally. Do not fabricate login.

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

Flutter bridge plan:

```text
Flutter -> MethodChannel/platform bridge -> Android native Checkout Kit
Flutter -> MethodChannel/platform bridge -> iOS native Checkout Kit
```

Official Checkout Kit support verified for Swift, Android, and React Native.
No official Flutter package is assumed. Native bridging requires review before
implementation.

## Checkout Callbacks

Future checkout state must handle completed, cancelled, failed/error, and closed.
Do not infer order success because checkout UI closes; listen for official
completed result mechanisms.

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
