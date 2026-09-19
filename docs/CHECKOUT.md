# Shopify Checkout

Phase 7 Chunk 3 implements the Shopify Checkout integration foundation using the existing cart, checkout presenter, Customer Account, Shopify, analytics, and error boundaries.

Implemented:
- Guest and logged-in checkout request models.
- Existing customer compatibility through Customer Account access-token handoff fields.
- Shipping address and saved-address inputs with validation before checkout handoff.
- Discount code and gift-card fields passed into checkout review state.
- Shopify Markets-ready dynamic country, currency, and language configuration.
- Order review model for products, quantity, variant, price, shipping, discounts, taxes, and final total.
- Shopify-calculated totals only; the app does not calculate taxes manually.
- In-flight checkout preparation coalescing to prevent duplicate checkout starts.
- Checkout unavailable/error handling through existing CheckoutResult and AppException contracts.
- Analytics for checkout_started, checkout_completed, checkout_abandoned, and discount_applied only.

Security:
- Checkout uses Shopify cart checkout URLs and native/hosted checkout handoff.
- No custom payment gateway was added.
- No Shopify Admin API, client secret, private token, Firebase secret, or payment credential was added.

Client dependencies:
- Storefront Cart API mutations for cart creation, buyer identity, discount codes, gift cards, and checkout URL refresh.
- Native Shopify Checkout Kit bridge for Android/iOS or approved hosted checkout handoff.
- Shopify Markets configuration for supported countries, currencies, and local pricing.
- Shipping profiles/rates and tax settings configured in Shopify.
- Existing customer checkout compatibility through Customer Account OAuth and checkout buyer identity.
