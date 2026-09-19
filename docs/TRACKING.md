# Tracking

Phase 7 Chunk 4 adds tracking display from Shopify fulfillment data.

Implemented:
- Tracking number.
- Courier name.
- Tracking link presence.
- Shipment status.
- Tracking section is hidden when no fulfillment tracking data is available.
- Analytics tracks tracking_opened only when a tracking row is opened.

Client dependencies:
- Customer Account order history/detail GraphQL transport.
- Protected customer order data approval.
- Fulfillment tracking fields populated in Shopify or the fulfillment provider.
- External tracking-link launch handling in a later native/platform wiring pass.
