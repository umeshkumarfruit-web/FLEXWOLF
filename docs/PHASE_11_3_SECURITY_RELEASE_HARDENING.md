# Phase 11.3 Security And Release Hardening

## Security Status

- Backend base URLs are validated as HTTPS.
- Shopify endpoints are generated with `Uri.https` and reject URL-shaped shop domains.
- Shopify GraphQL transport rejects non-HTTPS endpoints, applies request timeouts, and uses safe retryable errors for network, timeout, throttling, and server failures.
- Remote image loading rejects non-HTTPS URLs before network access.
- Production config disables diagnostics and verbose logging.
- Logging redacts token, password, and API key patterns before output.

## Token Status

- Customer tokens are isolated behind `CustomerTokenStore`.
- Expired or non-remembered sessions are cleared during restore.
- Unauthorized customer responses clear stored customer tokens.
- Logout clears customer tokens and removes push registration.
- Shopify OAuth refresh and remote token revocation remain client dependencies until Customer Account OAuth/PKCE credentials are supplied.

## Firebase Status

- Firebase is behind gateway interfaces.
- FCM defaults to not configured and returns no token until client Firebase setup is supplied.
- Push token deletion is represented in the messaging gateway boundary.
- No Firebase service account files, generated options, private keys, or certificates are committed.
- Remote Config is limited to safe home content defaults through `FirebaseRemoteConfigGateway`.

## Shopify Status

- Flutter uses Storefront and Customer Account boundaries only.
- Admin API remains disabled in-app and requires a secure FLEXWOLF backend.
- No Shopify Admin token is present in Flutter code.
- Public Storefront token support is optional and separated from private Admin credentials.

## Release Hardening

- Release version remains centralized in `pubspec.yaml`.
- Android release builds use Flutter version metadata.
- Debug diagnostics are disabled for production config.
- Release assertions are removed by Flutter release mode.
- Signing keys and provisioning material remain ignored and must be supplied through GitHub Secrets.

## Client Dependencies

- Production `API_BASE_URL`.
- Production `SHOPIFY_STORE_DOMAIN`.
- Firebase project configuration for Android/iOS.
- Shopify Customer Account OAuth/PKCE credentials and redirect URI.
- Backend-supported token revocation/logout endpoint.
- Android signing secrets.
- Apple certificates, provisioning profile, and App Store Connect API secrets.
