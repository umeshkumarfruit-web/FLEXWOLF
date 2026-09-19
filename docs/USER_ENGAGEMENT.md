# User Engagement Foundation

Phase 8 Chunk 4 adds the reusable user-engagement foundation without introducing private credentials or rebuilding completed features.

Implemented:
- Recently viewed products with guest local cache, duplicate removal, newest-first ordering, and a 20 item history limit.
- Malformed local recently viewed, continue shopping, and alert cache records are ignored safely.
- Continue shopping state for last product and last collection/category handle.
- Reusable recommendation request architecture for recommended products, you may also like, similar products, and trending products.
- Shopify-backed recommendation fallback through the existing ProductRepository only.
- Back-in-stock and price-drop alert registration records with subscribe/unsubscribe behavior.
- Product page auto-tracks recently viewed products and exposes back-in-stock/price-drop registration actions.
- Home `recently_viewed`, `recommended_for_you`, and `back_in_stock` sections use engagement widgets when data is available.
- Loading, skeleton, empty, error, and retry UI states use existing widgets.
- Accessibility uses existing semantic product cards, buttons, live route semantics, and touch-friendly design components.

Analytics:
- `recently_viewed`
- `recommendation_click`
- `back_in_stock_registration`
- `price_drop_registration`

Security:
- Guest engagement data remains local.
- Logged-in sync is prepared behind repository boundaries only.
- No Firebase secrets, Shopify Admin API token, private tokens, or client secrets were added.

Client dependencies:
- Backend endpoint for logged-in recently viewed sync if required.
- Backend endpoint for back-in-stock inventory trigger subscriptions.
- Backend endpoint for price-drop alert subscriptions.
- Recommendation/personalization service decision if Shopify product lists are not enough.
- Customer identity mapping approval before server-side engagement sync.