# Customer account and navigation update

Search and wishlist now live together in the header. The bottom bar contains Home, Shop, Support, and Account, with explicit mapping to the existing router branches. Search opens the catalog search instead of the old placeholder.

Account has Sign in / Create account options using Shopify hosted email-code authentication, plus guest browsing. Shopify creates a new account through the same verified email flow. OAuth listens before opening the browser, validates callback state, and releases listeners after completion or timeout. Logout clears local tokens before browser logout; push registration failures do not block authentication. Remembered tokens use device secure storage initialized in bootstrap; temporary sessions remain in memory only.

Customer profile and saved address reads now use Customer Account GraphQL discovery and the current session token. Profile/address mutations and order queries are still existing integration gaps and are outside this authentication/navigation update. This is not a full production-readiness certification.

## Live verification required

Provide SHOPIFY_STORE_DOMAIN, SHOPIFY_CUSTOMER_ACCOUNT_CLIENT_ID (public mobile client), and SHOPIFY_CUSTOMER_ACCOUNT_REDIRECT_URI through local build configuration. Register the exact callback and post-logout URI in Shopify. Use tools/build_android.ps1 so Android intent filters match the configured callback. iOS requires matching URL schemes and a macOS device build.

Verify on a real device: new email creates an account, returning email signs in, browser returns to Account, remembered login survives restart, temporary login does not survive restart, logout removes local access, then sign in as a different customer. Verify profile access scopes in Shopify. No customer email-code sign-in has been performed in this workspace session.

## References

- https://shopify.dev/docs/api/customer/latest
- https://shopify.dev/docs/api/customer-authentication
- https://shopify.dev/docs/api/customer/latest/objects/CustomerAddress
- https://pub.dev/packages/flutter_secure_storage
