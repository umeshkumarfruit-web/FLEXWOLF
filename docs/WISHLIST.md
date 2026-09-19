# Wishlist

Phase 8 Chunk 1 adds the production Wishlist foundation using existing Product, Customer Account, Shopify, storage, analytics, cart, and navigation contracts.

Implemented:
- Add, remove, toggle, view, count, and empty wishlist states.
- Guest wishlist stored through LocalStorage.
- Customer-keyed wishlist store and guest merge after login foundation.
- Product cards resolve Shopify products by handle and do not duplicate catalog data.
- Wishlist item actions: image, title, price, compare-at price, availability, variant preview, move to cart, remove, and open product details.
- Loading, skeleton, empty, error, retry, accessibility semantics, and lazy list rendering.
- Duplicate wishlist items and duplicate product fetches are prevented.
- Malformed local wishlist cache records are ignored safely and fall back to an empty usable state.
- Analytics limited to wishlist_viewed, product_added_to_wishlist, product_removed_from_wishlist, and wishlist_move_to_cart.

Client dependencies:
- Customer Account-backed wishlist persistence/metafield/backend decision.
- Storefront cart mutations for live Move to Cart.
- Final product handles/IDs from live Shopify data.
- Optional server sync if Shopify Customer Account does not support the selected wishlist persistence directly.
