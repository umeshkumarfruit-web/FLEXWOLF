# Customer Authentication Foundation

Phase 7 Chunk 1 implements the native account authentication foundation on the existing Shopify Customer Account contracts. Session restore, auto-login eligibility, expiry cleanup, unauthorized cleanup, logout cleanup, guest mode, login validation, loading/error/empty/retry/offline states, accessibility semantics, and secure token persistence are wired through the existing repository, secure storage, dependency injection, router, design system, connectivity, error, and analytics abstractions.

The supported production path is Shopify Customer Account OAuth/PKCE. FLEXWOLF website customers authenticate against Shopify Customer Accounts through the client-owned OAuth configuration and hosted customer account flow. The app does not create a duplicate customer database and does not use Shopify Admin API.

## Implemented in Phase 7.1

- Login foundation delegates to Customer Account OAuth/PKCE coordination after local form validation.
- Logout clears customer session state through the secure token store.
- Guest mode keeps product browsing, search, collections, and cart access available without customer authentication.
- Session restore only restores unexpired sessions that were saved with remember-session enabled.
- Expired, non-remembered, and unauthorized sessions are cleared from secure storage.
- Analytics tracks only login_success, login_failure, logout, and session_restored.
- Android build automation reads `.env` and forwards Customer Account public config through Flutter `--dart-define` values.

## Runtime Configuration

Use these app-side values for Customer Account setup:

- `SHOPIFY_CUSTOMER_ACCOUNT_CLIENT_ID`: public Customer Account API/mobile OAuth client id from Shopify Headless/Customer Account API settings. This is not the generic `SHOPIFY_API_KEY`. Shopify must have Customer Account OAuth and the callback URI enabled for this client.
- `SHOPIFY_CUSTOMER_ACCOUNT_REDIRECT_URI`: app-owned callback URI that is also allowlisted in Shopify.
- `SHOPIFY_CUSTOMER_ACCOUNT_ACCESS_TOKEN`: optional development/staging-only manual test token. Do not set in production.
- `SHOPIFY_CUSTOMER_ACCOUNT_TOKEN_EXPIRES_AT`: ISO-8601 expiry for the temporary development/staging token.

Client secret is not an app-side value. Keep `SHOPIFY_API_SECRET`, Customer Account client secrets, Admin API access tokens, and private Storefront tokens in Firebase/Cloud secret storage or another approved backend secret manager only.

## Client Dependencies

- Shopify Customer Account API enabled for the FLEXWOLF storefront.
- Public mobile Customer Account client ID.
- Approved redirect URI for Android App Links and iOS Universal Links.
- OAuth authorization, token, logout, and Customer Account GraphQL endpoint discovery/transport.
- Native browser handoff and callback handling for PKCE completion.
- Protected customer data approval before profile, address, and order surfaces are enabled.

## Security Notes

- Customer tokens are stored only through the existing SecureStorage abstraction.
- Passwords are never persisted and are cleared after a successful delegated auth result.
- No client secret, private API key, Shopify Admin token, Firebase secret, or password database is stored in Flutter.
- Shopify Admin API remains backend-only if ever approved in a later phase.
