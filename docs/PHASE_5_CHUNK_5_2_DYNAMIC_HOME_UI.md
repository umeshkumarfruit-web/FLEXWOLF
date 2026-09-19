# Phase 5 Chunk 5.2 Dynamic Home UI And Renderers

Status: COMPLETE for Chunk 5.2 renderer/UI scope with documented client and later-phase dependencies.

This chunk builds on Phase 5.1 only. It does not start Phase 5.3, Phase 6, or any admin/CMS management interface.

## Existing State Verified

Before implementation, the project was inspected for:

- Phase 1 environment/planning docs.
- Phase 2 Flutter/Riverpod/GoRouter/core infrastructure.
- Phase 3 Shopify Storefront, Customer Account, Checkout, and Admin API server-only boundaries.
- Phase 4 design system, reusable widgets, app shell, onboarding, preferences, bad-internet UI, accessibility, logging, storage, analytics abstraction, and tests.
- Phase 5.1 typed Home schema, section registry, scheduling, destinations, repository/data-source abstraction, cache fallback, and tests.

The Home tab previously rendered a generic Phase 4 placeholder. It now renders the Dynamic Home screen.

## Dynamic Home Screen

Implemented in `lib/features/home/presentation/dynamic_home_screen.dart`.

Behavior:

- Loads Home config through `homeContentResultProvider` and `HomeContentRepository`.
- Uses `HomeConfig.activeSections(nowUtc)` to respect enabled state and UTC scheduling.
- Renders sections in configured order.
- Uses `CustomScrollView`/slivers for scalable image/product-heavy Home content.
- Supports pull-to-refresh through provider invalidation.
- Shows skeleton loading state instead of a single full-page spinner.
- Shows stale cached-content banner when content comes from last-known-good cache.
- Shows safe retry/error state when no remote or cached Home config is available.
- Tracks provider-neutral Home view and section impression events.

## Renderer Registry

Implemented in `lib/features/home/presentation/renderers/home_section_renderer_registry.dart`.

All 22 contract section types have renderer mappings. The Home page does not contain a giant switch statement; it delegates renderer selection to the registry.

## Renderer Status By Section

| Section | Chunk 5.2 Status |
| --- | --- |
| Main Hero Banner | Renderer implemented. Uses configured image/text/CTA/action/accessibility metadata. |
| New Drop | Product rail renderer implemented. Real data requires configured Shopify references. |
| New Arrivals | Collection/product rail renderer implemented. Real data requires configured Shopify collection handle/id. |
| Best Sellers | Collection/product rail renderer implemented. Real data requires configured Shopify collection handle/id. |
| Trending | Collection/product rail renderer implemented. Real data requires configured Shopify collection handle/id or later signal provider. |
| Sale | Collection/product rail renderer implemented. Prices/discounts remain Shopify-sourced. |
| 365 Collection | Collection feature renderer implemented. Real collection identity/content is client dependency. |
| Flex Arm Collection | Collection feature renderer implemented. Real collection identity/content is client dependency. |
| Shorts | Collection feature renderer implemented. Real collection identity/content is client dependency. |
| Sweats | Collection feature renderer implemented. Real collection identity/content is client dependency. |
| App Exclusives | Product rail renderer implemented. True offer enforcement remains later Shopify/backend work. |
| Recommended For You | Renderer-ready dependency state. Personalization engine is later contract work. |
| Recently Viewed | Renderer-ready dependency state. Privacy-safe recently-viewed history is later contract work. |
| Complete The Look | Product rail renderer implemented for configured complementary Shopify products. No fake recommendation intelligence. |
| Creator Picks | Editorial product renderer implemented. Approved creator content/assets required. |
| Athlete Picks | Editorial product renderer implemented. Approved athlete content/assets required. |
| Shoppable Videos | Media renderer/interface implemented. Approved provider/content required; no autoplay/provider added. |
| Customer UGC | Media renderer/interface implemented. Approved moderated content required; no scraping/fabrication. |
| Back In Stock | Renderer-ready dependency state. Subscription/notification and inventory trigger work deferred. |
| Limited Drop | Collection/product rail renderer implemented. Secure purchase rules deferred to Shopify/backend. |
| Countdown | Countdown renderer implemented with UTC end time, app-resume refresh, non-negative labels, and no leaking timers. |
| Member Exclusive | Renderer-ready dependency state. FLEXWOLF membership remains a future contract dependency. |

## Shopify Integration

Home product and collection rails use `HomeCommerceResolver` and the Phase 3 Shopify repository boundary. No duplicate production product model was created.

Product cards use `ProductSummary`, `ProductVariant`, `ProductImage`, and `Money` from the existing Shopify domain. Prices are displayed as Shopify currency code plus decimal amount; no USD symbol or one-market pricing assumption was added.

No full Shopify catalog fetch was added. Rails resolve only configured product/collection references.

## Navigation And Actions

Implemented in `lib/features/home/presentation/home_action_dispatcher.dart`.

Supported typed destinations:

- product
- collection
- internal route
- search
- promotion/drop
- external URL handoff placeholder
- none

Because PDP and collection detail routes are not implemented yet, product/collection/drop actions route safely through the existing Shop route with typed `extra` metadata for later deep-link handling. No raw `Navigator.push` calls or hardcoded widget-local URLs were scattered through renderers.

## Development Preview

`DevelopmentHomeContentDataSource` provides a development-only renderer preview for all 22 section types when the app environment is development.

It is not production CMS truth, does not contain customer/order data, and does not create a fake CMS account. Staging and production still use the explicit client-dependency remote source until FLEXWOLF provides the final CMS/Remote Config provider.

## Loading, Error, Empty, Offline

Implemented:

- Home-level skeletons.
- Product rail skeletons.
- Section-level Shopify failure state.
- Empty rail dependency state unless explicitly hidden by config.
- Stale cached Home banner.
- Safe unavailable Home retry state.

One failed rail does not crash the full Home screen.

## Accessibility

Implemented:

- Hero/banner semantics and image alt text support.
- CTA semantic labels from schema.
- Section headings remain semantic headers.
- Product card semantic labels include availability.
- Countdown has readable semantic remaining-time text and no negative values.
- Touch feedback uses Material/InkWell with existing button/card components.

Full screen-reader QA on real content remains required after CMS/assets are supplied.

## Performance

Implemented:

- Sliver-based Home rendering.
- Lazy section construction through `SliverList.builder`.
- Section-level renderer registry.
- Product rails own their async future per section, avoiding repeated resolver calls on every rebuild.
- Product de-duplication inside a rail.
- No startup-blocking Home work outside the Home route.
- No autoplay video implementation.

## Security And Privacy

No secrets, Admin API tokens, client secrets, service accounts, private API keys, database passwords, or signing keys were added.

No customer data export, UGC scraping, fake personalization, fake membership, or duplicate ecommerce database was introduced.

## Tests

Added `test/home_dynamic_ui_test.dart` covering:

- Renderer registry mapping for all 22 section types.
- Dynamic ordering/enabled/scheduled section behavior.
- Hero rendering.
- Product rail loading.
- Product rail empty state.
- Product rail API failure.
- Product navigation through route boundary.
- Invalid destination safety.
- Countdown expiry/active rendering.
- Cached Home stale banner.
- Malformed optional section isolation.

Existing app shell/onboarding tests were updated only where the old Home placeholder was intentionally replaced by Dynamic Home.

## Client Dependencies

- FLEXWOLF CMS/Remote Config provider decision and access.
- FLEXWOLF Shopify collection handles/IDs for Home rails.
- Real Home banners, campaign copy, and approved images.
- Creator/athlete identities, approvals, and assets.
- Approved moderated UGC content/provider.
- Approved shoppable video provider/media URLs.
- Personalization/recently-viewed architecture approval.
- Membership requirements if Member Exclusive becomes visible.
- FLEXWOLF-owned Firebase project access if Remote Config is chosen.
- FLEXWOLF-owned GitHub repository/access.

## Later Contract Phase Dependencies

- PDP route and collection detail route.
- Cart/quick-add implementation.
- Personalization engine.
- Recently viewed storage/sync.
- Back-in-stock subscriptions/notifications.
- App-exclusive/member-exclusive server-side eligibility enforcement.
- CMS/admin controls in Phase 5 Chunk 5.3.
