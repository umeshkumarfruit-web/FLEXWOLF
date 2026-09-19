# Storefront Data Foundation

LIVE SHOPIFY CONNECTION: NOT TESTED — CLIENT ACCESS REQUIRED

No valid FLEXWOLF Shopify Storefront configuration is available in the local
project. Phase 3 Chunk 2 therefore uses repository interfaces and fixtures only
for automated parser/unit tests. Fixture data is not live Shopify data and is not
wired into production runtime.

## Product Data

Domain models support Shopify product ID, handle, title, descriptions, product
type, vendor, tags, featured image, image gallery, media/video, variants, options,
SKU, availability, price, compare-at price, currency, metafields, collection IDs,
and update metadata where present.

Optional Shopify data remains nullable/optional. The app does not invent required
fields that Shopify does not guarantee.

## Money And Markets

`Money` stores decimal amounts as validated strings and currency codes. UI-level
formatting can be added later. The app must not perform manual currency
conversion when Shopify Markets/localized pricing should provide regional values.

Future Markets requirements include countries, currencies, regional pricing,
regional inventory, taxes, duties, and shipping.

## Categories Register

Contract categories preserved for later Shop UI:

- New Arrivals
- Best Sellers
- Tees
- Tanks
- Shorts
- Joggers
- Sweatshirts
- Hoodies
- Accessories
- Sale

Do not assume these exact Shopify collection handles. Category-to-collection
mapping must come from Shopify/CMS configuration after access exists.

## Metafields

Potential future uses include fabric, fit, care, size information, model
information, app-specific flags, and merchandising metadata. Namespace/key names
must be inventoried from FLEXWOLF Shopify before use.

## Metaobjects

Potential future uses include dynamic home content, promotional content,
creator/athlete content, size guides, merchandising content, and configurable app
sections. Schema definitions must be inventoried from FLEXWOLF Shopify before
implementation.

## Tags And Badges

Future badge source must be evidence-based:

| Badge | Possible Sources | Decision Status |
| --- | --- | --- |
| NEW | Shopify data, metafield, tag, CMS rule, derived app rule | Needs Shopify evidence |
| SALE | Compare-at price, discount, tag, CMS rule | Needs Shopify evidence |
| BEST SELLER | Shopify data, metafield, metaobject, CMS rule | Needs Shopify evidence |
| APP EXCLUSIVE | Metafield, metaobject, tag, CMS rule | Needs Shopify evidence |
| LOW STOCK | Inventory rule, metafield, derived app rule | Needs Shopify evidence |
| RESTOCKED | Inventory rule, metafield, CMS rule | Needs Shopify evidence |

Do not build critical business logic entirely on guessed tags.

## Pagination And Query Cost

Repositories use Shopify cursor pagination (`first`, `after`, `pageInfo`). They
must not fetch the full catalog into memory. Query fields are organized into
fragments and should stay minimal by feature need.

Potentially expensive operations: large variant counts, rich media, metafields,
metaobjects, and broad search/filter queries. Add fields incrementally with cost
awareness.

## Cache And Weak Internet

Catalog caching is a controlled future boundary: bounded, environment-isolated,
stale-aware, refreshable, and never authoritative indefinitely for inventory or
pricing. Future UI should preserve already-loaded safe catalog data, show useful
errors, and support retry without blank screens.

## Inventory And Price Safety

Inventory and availability change quickly and must be revalidated during relevant
actions. Prices and compare-at prices must originate from Shopify. Do not hardcode
merchandising prices into app source.

## Cart And Checkout Boundary

Cart architecture is prepared for `cartCreate`, line add/update/remove, buyer
identity, checkout URL, cart retrieval, and cart attributes where genuinely
required. Guest checkout remains mandatory. Authenticated buyer identity may later
prefill/personalize Shopify checkout where supported.

Never construct fake payment pages. Never collect or store card numbers in a
custom FLEXWOLF backend.

## Bundle Readiness

Bundle architecture preserves future support for 1 Pack, 3 Pack, 5 Pack, 6 Pack,
different colors/sizes, quantity bundles, mix-and-match, automatic discounts,
Shopify bundles, and promotional bundles. Implementation must wait for actual
FLEXWOLF Shopify configuration. Bundle pricing must work correctly in Shopify
checkout.

## Search Readiness

Storefront repositories can later support product search, collection search,
predictive/instant suggestions, filters, and typo/search strategy after the
approved approach is selected.
## Collection Browsing

Phase 6 Chunk 2 adds native collection browsing on the Shop screen using the
existing Shopify Storefront collection repository. `All Products` is the only
non-collection entry and uses the product repository directly. Named storefront
areas such as New Arrivals, Best Sellers, Sale, 365 Collection, Flex Arm
Collection, Shorts, and Sweats remain configurable and must receive real Shopify
handles from client configuration before they can be treated as production
merchandising links.

The UI may display Shopify collection title, description, and image when returned
by Storefront. Product count remains optional and must not be invented when the
Storefront payload does not provide it.

## Filter Search And Sort

Phase 6 Chunk 3 adds native Shop search, sorting, and dynamic filter UI. Values for size and color are derived from Shopify product variants already loaded through the existing Storefront repositories. Product name, category/product type, and tag matching reuse the Shop product model; no second search backend is introduced. Future server-side Storefront search/filter handles must remain configurable and client-provided.

## Product Page And Cart Foundation

Phase 6 Chunk 4 adds native product detail rendering from existing Shopify product models. Variant, price, compare-at price, SKU, availability, image, and option data must originate from Storefront. Cart and Buy Now use existing CartRepository and CheckoutPresenter contracts; local runtime remains client-dependent until Shopify cart mutations and native checkout are configured.

