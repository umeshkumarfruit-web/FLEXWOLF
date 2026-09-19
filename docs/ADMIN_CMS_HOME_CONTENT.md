# Admin CMS and Home Content Management

Phase 10 Chunk 2 adds the Admin Portal CMS/Home Content Management foundation. It reuses the existing dynamic Home config contract and does not implement Phase 10 Chunk 3, Shopify Admin API editing, Firebase project setup, live media upload, or unfinished admin modules.

## Scope Completed

- Content destination in the Admin Portal now opens the CMS management module.
- Home CMS draft model covers Hero Banner, Featured Collections, Promotional Cards, Announcement Bar, Featured Products, New Arrivals, Best Sellers, Sale Section, Video Banner, and Footer Content.
- Banner management supports add, edit, delete, enable/disable, reorder, and preview.
- Content lifecycle supports draft, scheduled, published, and unpublished states.
- Scheduling architecture supports start and optional end times with validation.
- Featured collection management stores Shopify collection references only; it does not duplicate Shopify collection records.
- Media architecture supports banner images, promotional images, and video placeholders. Upload remains behind a secure gateway contract.
- Preview exports JSON through the existing `HomeConfig` schema so the storefront renderer remains the source of truth.
- UI includes loading, skeleton, empty, error, and retry states through existing shared components.
- Analytics is limited to `cms_viewed`, `banner_updated`, and `content_published`.

## Remote Config

Firebase Remote Config publishing is prepared through the admin CMS publisher boundary. Production publishing is CLIENT DEPENDENCY until FLEXWOLF provides a secure backend or approved Firebase-admin service. Flutter must not contain Firebase service account files, Admin SDK credentials, private keys, or private tokens.

## Security

No Shopify Admin API token, Firebase secret, private API key, service account credential, media upload secret, or backend credential was added to the Flutter app.

## Client Dependencies

- Firebase Remote Config project/backend publishing endpoint.
- CMS persistence endpoint or approved admin backend.
- Secure media upload endpoint and CDN policy.
- Final Home content taxonomy, scheduling approval rules, and preview/publish workflow approval.
- Admin role permission mapping for CMS write/publish actions.

## Phase 10 Final Readiness

CMS and Home content management are production-ready as an admin foundation. Live persistence, Remote Config publishing, media upload, and approval governance remain CLIENT DEPENDENCY until the production Firebase/backend/media contracts are provided.
