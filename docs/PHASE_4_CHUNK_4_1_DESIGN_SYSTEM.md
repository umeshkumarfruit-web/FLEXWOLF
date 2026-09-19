# Phase 4 Chunk 4.1 - Design System Foundation

Status: PARTIAL

This chunk creates the native Flutter visual foundation for FLEXWOLF. It does not implement Dynamic Home, Shop, Cart, Checkout, Customer Account, Firebase, Klaviyo, Admin/CMS, or Phase 4 Chunk 4.2 work.

## Approved visual source

Primary visual reference: `https://flexwolf.co`.

Observed direction from the live site on 2026-09-01:

- Black/white/neutral visual identity.
- Premium athletic and streetwear tone.
- Bold product-first hierarchy.
- Product cards with large imagery, quick-add CTAs, badges, sale/regular price treatment, and compact product metadata.
- Promotional bars including sale, shipping, and return messaging.
- Shop categories such as New Arrivals, Tanks, Tees, Bottoms, Bundles, and Last Call.
- Brand copy includes: premium athletic/streetwear, no fluff/no filler, and Trust Like a Wolf.

## Design responsibility

Final editable design files are not present in the repository. No Figma, Sketch, XD, or approved brand book was found.

Current implementation responsibility: developer-created native Flutter foundation using `flexwolf.co` as visual reference.

Final visual approval status: CLIENT DEPENDENCY / APPROVAL REQUIRED.

## Assets

Assets inspected:

- `assets/images/`
- `assets/icons/`
- `assets/fonts/`
- `assets/animations/`
- platform launcher icons

No approved FLEXWOLF production logo, custom font, product imagery, icon pack, banners, or animation assets were found in the Flutter asset folders.

CLIENT DEPENDENCY: provide approved logo files, production imagery/banners, final app icon assets if different from current placeholders, and final font licensing/approval.

## Token locations

Central design tokens live in `lib/core/design/design_tokens.dart`:

- colors
- typography
- spacing
- screen padding
- radii
- borders
- elevations
- icon sizes
- touch targets
- motion durations
- motion curves
- responsive breakpoints
- image aspect ratios

App theme wiring lives in `lib/app/theme/app_theme.dart`.

## Typography

Typography is centralized in `AppTypography` with styles for display, page title, section title, product title, body, small body, CTA, price, sale price, labels, captions, and navigation labels.

No unlicensed custom commercial font was added. `AppTypography.fontFamily` remains centralized for later approved font installation.

## Colors

The previous unapproved green/beige temporary token direction was replaced with centralized black/white/neutral FLEXWOLF-aligned tokens. Sale/error/success/warning colors remain semantic and restrained.

Exact final brand color approval remains CLIENT DEPENDENCY / APPROVAL REQUIRED.

## Responsive system

Responsive helpers live in `lib/core/layout/responsive_page_padding.dart`:

- small Android phone support
- common/larger phone width classes
- max content width for larger devices
- SafeArea helper
- keyboard inset padding
- text scaling clamp
- no device-specific hardcoded widths

## Reusable components

Reusable components live under `lib/core/widgets/`:

- `AppButton`
- `AppIconActionButton`
- `FlexwolfHeader`
- `FlexwolfLogo`
- `AppSectionHeading`
- `AppImageContainer`
- `AppRemoteImage`
- `AppProductCardShell`
- `AppPrice`
- `AppBadge`
- `AppDivider`
- `AppFormField`
- `AppSelectionTile`
- `AppPreferenceChip`
- `AppLoadingIndicator`
- `AppSkeletonLoader`
- `AppEmptyState`
- `AppErrorState`
- `AppRetryState`
- `AppOfflineState`
- `AppModalSheet`

These are foundation components only. They do not implement later ecommerce logic.

## Accessibility rules

Components include, where applicable:

- semantic labels
- button semantics
- enabled/disabled semantics
- selected/unselected semantics
- image semantics
- live-region loading/error/empty state semantics
- visible selected indicators beyond color only
- minimum 48 dp touch targets
- scalable text constraints
- tokenized contrast-aware colors

## Motion and haptics

Motion tokens are centralized in `AppDurations` and `AppCurves`. Current component motion is restrained and used for selection feedback.

Haptic utility lives in `lib/core/utils/app_haptics.dart`. It is available for selective confirmation/selection feedback and is not triggered on every tap globally.

## Performance notes

The component foundation favors const constructors, simple widget trees, theme-level configuration, fixed aspect ratios, and no eager asset loading. Product images remain caller-provided; image caching/package changes are deferred until real catalog screens require them.

## Security notes

No Shopify secret, Admin API token, private Storefront token, Klaviyo private key, Firebase service account, signing key, or backend secret was added. No `.env` behavior was changed.

## Client dependencies

- Final editable design files or written approval that developer-created native designs based on `flexwolf.co` are acceptable.
- Approved logo asset.
- Approved font and licensing confirmation.
- Approved product/category/banner imagery for native app use.
- Final brand color token approval.
- Final design review approval after visual screens are assembled in later Phase 4 chunks.
