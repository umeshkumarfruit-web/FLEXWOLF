# Product Reviews

Phase 9.2 adds the Product Reviews module behind a provider-neutral
repository contract.

## Current Status

- Product details renders a reusable reviews section.
- Review summary supports average rating, total reviews, and rating breakdown
  when the provider supplies those fields.
- Review list supports latest, highest rating, lowest rating, and helpful sort
  requests through the review repository contract.
- Review details support customer name, rating, title, comment, date, verified
  purchase, helpful count, images, and videos when supplied by the provider.
- Write review supports rating, title, comment, image attachment placeholder,
  validation, submission state, and error handling.
- Loading, skeleton, empty, error, and retry states are implemented.
- Review requests are cached and de-duplicated at the repository boundary.
- Analytics events are limited to reviews viewed, write review opened, and
  review submitted.

## Client Dependency

The client's existing Reviews Platform API details are required before live
data can be enabled:

- Provider API base URL or SDK details.
- Public client credentials or backend proxy endpoint for read operations.
- Secure backend submission endpoint for write review operations.
- Product identifier mapping between Shopify product IDs/handles and the
  Reviews Platform.
- Provider support confirmation for verified purchase, helpful ordering,
  images, and videos.

No review provider credentials, Shopify Admin API tokens, private tokens, or
secrets should be stored in the Flutter app.

## Integration Contract

Implement `ProductReviewRepository` in
`lib/features/reviews/domain/product_reviews.dart` and replace the current
`ClientDependencyReviewRepository` binding in
`lib/features/reviews/data/review_providers.dart`.
## Phase 9.4 Integration Notes

- Product Details surfaces rating summary, View All Reviews, Write Review, Product Support, and Related Products without replacing the existing product page.
- Review submission now returns an explicit success confirmation when the provider accepts the request.
- Customer Profile exposes My Reviews as a CLIENT DEPENDENCY because customer-specific review history requires provider credentials or a secure backend endpoint.
## Phase 9.5 Production Readiness

- Review summary, list, sorting, write-review validation/submission state, success confirmation, empty/error/retry states, and provider-supplied image/video media display were reviewed.
- Review read requests remain cached and de-duplicated at the repository boundary.
- Live review data, customer review history, media upload, verified purchase, and moderation behavior remain CLIENT DEPENDENCY until the provider contract is supplied.

