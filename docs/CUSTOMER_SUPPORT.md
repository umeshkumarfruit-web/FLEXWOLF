# Customer Support

Phase 9.3 adds the FLEXWOLF customer support module.

## Scope

- Support home with Help Center, FAQ, Contact Support, Order Support, and Product Support entry points.
- FAQ categories, search, expand/collapse answers, cached local content, and duplicate request prevention.
- Contact Support form with name, email, subject, message, optional order number, and optional product context.
- Order support can be opened from order history order details.
- Product support can be opened from product detail pages.

## Analytics

Only these support events are tracked:

- `support_opened`
- `faq_viewed`
- `contact_submitted`

## Gorgias Integration

The app includes a reusable `GorgiasGateway` boundary and support repository integration point. No Gorgias credential, Shopify Admin API token, private token, or client secret is stored in the app.

Current status: CLIENT DEPENDENCY.

The client must provide a secure server-side ticket endpoint or approved Gorgias proxy. Mobile apps must not call Gorgias with private credentials directly.

## Client Dependencies

- Gorgias API credentials or server-side Gorgias ticket creation endpoint.
- Production Help Center or CMS FAQ source if default FAQ content should be replaced.
- Final support policy content for shipping, returns, exchanges, and sizing.
## Phase 9.4 Integration Notes

- Support can be opened from Customer Profile, Product Details, and Order Details while preserving order or product reference context.
- The support flow remains Support Home -> FAQ -> Contact Support -> Order Support using the shared cached support repository.
- Gorgias remains CLIENT DEPENDENCY and must be completed through a secret-safe backend or approved proxy; no private credentials belong in Flutter code.
## Phase 9.5 Production Readiness

- Support home, FAQ, contact support, order support, product support, cached FAQ data, duplicate contact submission prevention, and submission failure handling were reviewed.
- Shared retry/error UI is now scrollable in constrained mobile layouts after Android runtime validation exposed an overflow.
- Live Gorgias ticket creation and production Help Center content remain CLIENT DEPENDENCY and must use a server-side endpoint or approved proxy.

