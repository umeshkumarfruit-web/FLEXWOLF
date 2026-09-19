# Phase 5 Chunk 5.1 Dynamic Home Architecture

Status: COMPLETE for Chunk 5.1 architecture scope, subject to verification results in the final run log.

This chunk starts Phase 5 only. It does not create Phase 27+, does not start Chunk 5.2, and does not implement full Home section renderers.

## Existing Project Inspection

Verified before implementation:

- Phase 1 planning and environment documents remain present.
- Phase 2 Flutter app foundation remains feature-oriented with `lib/app`, `lib/core`, `lib/features`, and `lib/integrations`.
- State management remains Riverpod.
- Routing remains GoRouter with native Home, Shop, Search, Wishlist, and Account branches.
- Phase 3 Shopify Storefront, Customer Account, Checkout, and Admin API server-only boundaries remain present.
- Phase 4 design tokens, app theme, reusable widgets, shell navigation, onboarding, preferences, bad-internet widgets, analytics abstraction, logging, local storage, privacy, and connectivity boundaries remain present.
- Firebase and CMS remain boundary-only; no production account/configuration is present.
- Local Git exists, but the workspace contents are untracked and no official FLEXWOLF-owned GitHub remote/access was verified.

## Home Schema

The Home schema is strongly typed in `lib/features/home/domain/home_config.dart` and supports:

- `schemaVersion`
- `sectionId`
- `sectionType`
- `enabled`
- `displayOrder`
- title, subtitle, body/copy, CTA text
- desktop/mobile media references, alt text, aspect ratio
- typed destination/action
- Shopify product, variant, and collection references
- UTC `startsAt` and `endsAt` scheduling
- presentation metadata
- analytics metadata
- accessibility labels
- fallback behavior
- cache version/timestamp metadata

Remote configuration is treated as untrusted input. The parser validates required fields, schema versions, unknown section types, duplicate IDs, ordering, references, destinations, dates, empty sections, and malformed sections.

## Section Registry

`lib/features/home/domain/home_section_registry.dart` centrally registers all 22 contractual section types:

1. Main Hero Banner
2. New Drop
3. New Arrivals
4. Best Sellers
5. Trending
6. Sale
7. 365 Collection
8. Flex Arm Collection
9. Shorts
10. Sweats
11. App Exclusives
12. Recommended For You
13. Recently Viewed
14. Complete The Look
15. Creator Picks
16. Athlete Picks
17. Shoppable Videos
18. Customer UGC
19. Back In Stock
20. Limited Drop
21. Countdown
22. Member Exclusive

The registry maps each remote string to a typed enum and analytics name, and records whether the section depends on Shopify products, Shopify collections, personalization, or media-provider functionality. Unknown/future section types are skipped safely and exposed as diagnostics for logging.

## Repository And Data Sources

Provider-neutral contracts remain in `lib/features/home/domain/home_content_repository.dart`:

- `HomeContentRepository`
- `RemoteHomeContentDataSource`
- `CachedHomeContentDataSource`
- `HomeCommerceResolver`

Concrete Phase 5.1 foundations:

- `DefaultHomeContentRepository` validates remote content before use.
- `LocalCachedHomeContentDataSource` stores last-known-good config through the existing `LocalStorage` abstraction.
- Firebase Remote Config and CMS adapters are prepared as boundaries only.
- Riverpod providers expose injectable Home content dependencies.

No production CMS, Firebase project, or custom backend was created.

## Shopify Source Of Truth

Home configuration references Shopify entities only. It does not duplicate catalog, price, inventory, customer, order, fulfillment, or market data.

Supported references:

- Shopify product ID
- Shopify product handle
- Shopify product variant ID where applicable
- Shopify collection ID
- Shopify collection handle

Commerce resolution uses existing Phase 3 repository contracts. Product titles, descriptions, variants, sizes/colors, inventory, prices, compare-at prices, collections, customers, orders, and fulfillment remain owned by Shopify.

## Cache And Fallback

Behavior implemented:

- Remote fetch succeeds: validate config, use it, cache valid last-known-good config with cache timestamp/version.
- Remote fetch fails: use valid cached config if available.
- Remote config malformed: reject invalid remote config and use valid cached config if available.
- No remote and no cache: return a safe unavailable result for Home UI retry/error handling.
- Malformed remote or cached data is not stored as valid.

## Scheduling

`HomeSchedule` stores timezone-safe parsed `DateTime` values in UTC and supports testable active/inactive evaluation. Client-side scheduling only controls presentation. Purchase eligibility, member access, and restricted offers must later be enforced by Shopify/backend rules where required.

## Destinations And Deep-Link Boundary

`HomeDestination` supports:

- product
- collection
- internal route
- search
- promotion/drop
- approved external URL
- no action

Widgets should consume this typed model later and route through the existing app router/deep-link boundary. Chunk 5.1 does not implement full deep-link navigation.

## Analytics Readiness

The existing provider-neutral analytics abstraction was extended with event names for:

- `home_view`
- `home_section_impression`
- `home_section_click`
- `home_banner_click`
- `home_product_click`
- `home_collection_click`

No duplicate analytics system or live Firebase/GA4 claim was added.

## Accessibility

The schema supports section semantic labels, image alt text, CTA accessibility labels, and structured text fields. Important merchandising information should remain in structured text and not only inside images.

## Security And Privacy

No secrets were added. The mobile app still must not contain Shopify Admin API tokens, private Storefront tokens, Shopify Client Secrets, Klaviyo private keys, Firebase service accounts, database credentials, signing keys, or backend secrets.

No customer data export, personal CMS account, fake production Firebase project, or duplicate customer database was introduced.

## CMS And Remote Config Boundary

CLIENT DEPENDENCY / ARCHITECTURE DECISION REQUIRED: FLEXWOLF must choose/provide the final Home content provider and account access. Supported future providers include Shopify Metaobjects/Metafields, Firebase Remote Config, and a FLEXWOLF-controlled backend/CMS.

## Deferred To Chunk 5.2/5.3

- Dynamic Home visible UI and section renderers.
- Real Shopify product/collection rails on Home.
- Personalization engines for Recommended For You and Recently Viewed.
- Shoppable video playback/provider integration.
- Creator/athlete/UGC provider integration.
- Back-in-stock and member-exclusive eligibility enforcement.
- Production CMS/admin tooling and account wiring.
- Production Firebase Remote Config wiring.

## Phase 10.2 Admin CMS Note

Admin CMS management now prepares Home content through the existing dynamic Home config contract. Remote publish, CMS persistence, and media uploads remain CLIENT DEPENDENCY and must use secret-safe backend or Firebase-admin services; Shopify collections are referenced by handle/id and not duplicated.

