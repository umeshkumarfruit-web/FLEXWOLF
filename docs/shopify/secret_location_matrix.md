# Shopify Secret Location Matrix

| Configuration Item | Classification | Notes |
| --- | --- | --- |
| Shop domain | MOBILE SAFE CONFIG | Environment-specific; safe in app config. |
| Storefront API version | MOBILE SAFE CONFIG | `2026-07`. |
| Public Storefront token | MOBILE SAFE CONFIG | Only public token designed for mobile/browser use. Do not log. |
| Private Storefront token | SERVER SECRET | Never in Flutter. |
| Customer Account client ID | MOBILE SAFE CONFIG | Public mobile client identifier. |
| Customer Account redirect URI | PLATFORM CONFIG | Requires Android App Links / iOS Universal Links later. |
| Customer authorization endpoint | MOBILE SAFE CONFIG | Discovered endpoint. |
| Customer token endpoint | MOBILE SAFE CONFIG | Endpoint is safe; token values are sensitive. |
| Customer logout endpoint | MOBILE SAFE CONFIG | Discovered endpoint. |
| Customer access token | PLATFORM SECURE CUSTOMER TOKEN | Android Keystore/iOS Keychain-backed storage. |
| Customer ID token | PLATFORM SECURE CUSTOMER TOKEN | If returned by selected flow. |
| Refresh token | PLATFORM SECURE CUSTOMER TOKEN | Not expected for Shopify public mobile app clients per current docs; handle only if architecture changes. |
| Shopify Admin access token | SERVER SECRET | Backend-only. |
| Shopify Admin client secret/private key | SERVER SECRET | Backend-only if ever required. |
| Webhook secret | SERVER SECRET | Backend-only. |
| Android application ID | PLATFORM CONFIG | Client approval required. |
| iOS bundle identifier | PLATFORM CONFIG | Client approval required. |
