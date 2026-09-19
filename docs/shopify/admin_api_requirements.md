# Shopify Admin API Requirements Register

Admin API is not integrated in Flutter. Admin operations are disabled until a
real backend requirement is approved.

| Potential Use | Business Requirement | Why Storefront/Customer Account API Cannot Satisfy | Required Scopes | Security Plan | Status |
| --- | --- | --- | --- | --- | --- |
| Webhooks | Keep backend/CMS/cache in sync later | Storefront API is client-facing and does not receive server events | TBD | Backend endpoint with verified Shopify webhook signatures | NOT REQUIRED YET |
| Scheduled processing | Future backend automation | Client app should not run server jobs | TBD | FLEXWOLF backend with server secrets only | NOT REQUIRED YET |
| Custom CMS logic | Future app-specific content admin | Shopify may not own all app content | TBD | Backend/admin access control | NOT REQUIRED YET |
| Secure administrative operations | Only operations unavailable to Storefront/Customer APIs | Must be proven per feature | TBD | Backend-only Admin token in secret manager | NOT REQUIRED YET |

Architecture:

```text
Flutter
  -> HTTPS
FLEXWOLF Backend
  -> Shopify Admin API
```

No Admin API token, client secret, private key, or webhook secret belongs in the
Flutter app.
