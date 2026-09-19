# Phase 5 Chunk 5.3: Dynamic Home Hardening

Chunk 5.3 hardens the Phase 5.1 schema and Phase 5.2 native renderer pipeline.

## Content Controls Boundary

`RemoteHomeContentDataSource` remains provider-neutral. CMS and Firebase Remote Config adapters implement the boundary, while production provider selection remains a client dependency until FLEXWOLF supplies the approved project/provider access. A valid remote configuration can change section content, media, destinations, Shopify references, enabled state, display order, and UTC schedule without an app update.

The development environment uses an explicitly development-only preview source. Staging and production do not fall back to that preview.

## Validation And Versioning

`HomeConfigParser` accepts only supported schema versions, requires typed section identity/order, rejects invalid dates, ranges, destinations, reference lists, enabled values, negative order values, and duplicate IDs. Unknown section types are diagnostic-only and are skipped safely. An entirely malformed non-empty payload is rejected; valid sections can still render when an optional sibling is malformed. Schema migration is intentionally deferred until a future schema version needs it.

## Scheduling

`HomeSchedule` parses ISO-8601 timestamps and evaluates `startsAt <= nowUtc < endsAt`. Countdown rendering uses UTC, hides expired campaigns, refreshes on app resume, and disposes its lifecycle observer. Client visibility is presentation only; purchase eligibility requires Shopify/backend enforcement.

## Cache And Offline

A remote payload is parsed before it can be cached. Only a valid configuration is written as the last-known-good value. Cache reads validate the config, cached timestamp, and schema-matched cache version (`schema-<schemaVersion>`). Remote failure or malformed content uses the valid cache; no valid cache produces a safe retry state. Malformed cache is ignored.

## Commerce And Performance

Home resolves product and collection references through the existing Shopify Storefront repository boundary. It does not duplicate catalog, order, customer, inventory, or pricing data. `CachingHomeCommerceResolver` coalesces identical in-flight product and collection requests during a Home session. Missing/deleted commerce entities are omitted or shown as section-level empty/error states.

## Accessibility And Analytics

Renderers provide section, image, CTA, product-card, and countdown semantic labels. Product prices use Shopify money currency codes and do not assume USD. Home view, section impressions, hero/product/collection/CTA and shoppable-video event names are prepared through the existing provider-neutral analytics abstraction without customer PII.

## Dependencies And Deferred Work

Client dependencies remain: approved CMS/Firebase provider and access, final Home creative/content, Shopify handles/IDs, creator/athlete/UGC/video approvals, personalization/recently-viewed services, membership enforcement, and official FLEXWOLF GitHub access. CMS/admin controls, final offline/performance audit, production analytics wiring, and full Phase 5 contract audit remain intentionally for the next contracted phase/chunk outside this implementation.
