# Orders

Phase 7 Chunk 4 adds the Order Management experience through the existing Shopify Customer Account repository.

Implemented:
- Order history surface in the signed-in account area.
- Newest-first order list with order number, date, dynamic Shopify status, payment status, fulfillment status, item count, and total.
- Order details for products, variants, quantity, price, discount, shipping, taxes, final total, shipping address, and billing address.
- Loading skeleton, empty, error, retry, offline fallback, pagination, lazy list rendering, and duplicate request guard.
- Order actions for details, reorder entry, support, return/exchange, and future invoice backend placeholder.

Statuses are displayed from Shopify response fields and are not hardcoded to a fixed enum.
