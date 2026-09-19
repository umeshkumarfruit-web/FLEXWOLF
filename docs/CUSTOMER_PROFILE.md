# Customer Profile

Phase 7 Chunk 2 adds the Customer Profile module on the existing Shopify Customer Account architecture.

Implemented:
- Profile view for customer name, email, phone, default shipping address, default billing address, avatar placeholder, and account status.
- Pull-to-refresh and refresh action.
- Edit profile entry with first name, last name, and phone validation.
- Loading, empty, error, retry, and offline states through existing shared widgets.
- Logout and session information in account settings.
- Privacy, terms, and change-password entries as Customer Account handoff placeholders.

Customer data remains owned by Shopify. The app does not create duplicate customer records and does not use Shopify Admin API.

Client dependencies:
- Customer Account GraphQL profile read transport.
- Protected customer data approval for name, email, phone, and addresses.
- Customer profile update mutation support where enabled by Shopify/customer account configuration.
- Customer Account hosted password/settings URL or supported handoff flow.
