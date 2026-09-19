# Address Management

Phase 7 Chunk 2 adds the Address Management module on the existing Customer Account repository contract.

Implemented:
- Address list UI.
- Add, edit, delete, set default shipping, and set default billing actions.
- Required-field validation before save attempts.
- Loading, empty, error, retry, and offline states.
- Accessibility semantics for profile, address, settings, and action controls.
- Analytics for profile_viewed, address_added, address_updated, and address_deleted only.

Address operations delegate to Shopify Customer Account API contracts. Until client-owned Customer Account write transport and protected data approval are configured, write attempts return client-dependency errors instead of storing local customer data.

Client dependencies:
- Customer Account GraphQL address read/write transport.
- Approved customer_write_customers scope where required.
- Protected customer data approval for customer addresses.
- Confirmation of Shopify support for separate default shipping and billing behavior in the selected customer account mode.
