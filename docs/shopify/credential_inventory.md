# Shopify Credential Inventory

Do not write actual private values in this document or in Flutter source code.

## Storefront

| Item | Status | Location Class | Notes |
| --- | --- | --- | --- |
| Shop domain | CLIENT ACTION REQUIRED | MOBILE SAFE CONFIG | Environment-specific. |
| Storefront API version | AVAILABLE | MOBILE SAFE CONFIG | Selected stable `2026-07`. |
| Public Storefront access token | CLIENT ACTION REQUIRED | MOBILE SAFE CONFIG | Mobile/browser-visible token where Shopify officially allows public access. |
| Private Storefront access token | NOT REQUIRED YET | SERVER SECRET | Server-only if future backend needs it. |

## Customer Account

| Item | Status | Location Class | Notes |
| --- | --- | --- | --- |
| Customer-account client ID/config | CLIENT ACTION REQUIRED | MOBILE SAFE CONFIG | Public mobile client with PKCE where applicable. |
| Client type | CLIENT ACTION REQUIRED | PLATFORM CONFIG | Expected public mobile client; confirm in Shopify config. |
| Redirect URI(s) | CLIENT ACTION REQUIRED | PLATFORM CONFIG | Must be approved app link/universal link; do not invent. |
| Authorization endpoint | CLIENT ACTION REQUIRED | MOBILE SAFE CONFIG | Discovered from `/.well-known/openid-configuration`. |
| Token endpoint | CLIENT ACTION REQUIRED | MOBILE SAFE CONFIG | Discovered; do not log token responses. |
| Logout endpoint | CLIENT ACTION REQUIRED | MOBILE SAFE CONFIG | Discovered endpoint. |
| GraphQL endpoint | CLIENT ACTION REQUIRED | MOBILE SAFE CONFIG | Discovered from `/.well-known/customer-account-api`. |
| Client secret | NOT REQUIRED YET | SERVER SECRET | Only for confidential server architecture if approved. |

## Admin / Backend

| Item | Status | Location Class | Notes |
| --- | --- | --- | --- |
| Admin API access token | NOT REQUIRED YET | SERVER SECRET | Backend only, never Flutter. |
| Webhook secret | NOT REQUIRED YET | SERVER SECRET | Backend only. |
| Private signing keys | NOT REQUIRED YET | SERVER SECRET | Backend/secret manager only. |
