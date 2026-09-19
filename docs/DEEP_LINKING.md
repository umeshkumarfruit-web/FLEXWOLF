# Deep Linking And Notification Navigation

Phase 8 Chunk 3 adds validated deep-link navigation on top of the existing GoRouter shell and Phase 8.2 notification pipeline.

Supported destinations:
- Home: `/`
- Product: `/products/{handle}` -> `/shop/products/{handle}`
- Collection: `/collections/{handle}` -> `/shop/collections/{handle}`
- Wishlist: `/wishlist`
- Cart: `/cart` -> friendly fallback until cart route is configured
- Checkout: `/checkout` -> friendly fallback until checkout route is configured
- Order details: `/account/orders/{id}` -> Account route until direct order detail route is available
- Customer profile: `/account/profile` -> Account route
- Promotions: `/offers/{id}` or `/drops/{id}` -> `/shop/promotions/{id}`

Navigation behavior:
- Cold-start, background, and foreground entry points use the same parser contract.
- Notification taps use the same validation path as app deep links.
- Duplicate notification opens are suppressed by notification id.
- Unknown, unsafe, missing, deleted, or unsupported links route to the accessible fallback screen.\n- Notification navigation uses the same parser and duplicate-open suppression as app deep links.

Analytics:
- `deep_link_opened`
- `notification_navigation`
- `destination_loaded`

Security:
- Incoming paths are length-limited and identifiers are allowlisted.
- Unsupported schemes are rejected.
- Notification payload deep links are treated as untrusted input.
- No Firebase private credentials, Shopify Admin API token, client secret, or private token is stored in the client.

Client dependencies:
- Android App Links / iOS Universal Links domain ownership and association files.
- Final public route-domain policy for FLEXWOLF production links.
- Live Shopify product/collection availability checks for direct detail fallback precision.
- Direct cart, checkout, and order-detail screens when those product contracts are ready.