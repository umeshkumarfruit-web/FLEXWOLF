# FLEXWOLF Phase 2 Architecture Plan

Status date: 2026-08-31

This is an architecture plan only. Phase 1 Chunk 2 does not create the final production FLEXWOLF app structure.

## Planned Folder Structure

```text
flexwolf/
|-- lib/
|   |-- app/
|   |   |-- app.dart
|   |   |-- router/
|   |   |-- theme/
|   |   |-- config/
|   |
|   |-- core/
|   |   |-- constants/
|   |   |-- errors/
|   |   |-- network/
|   |   |-- storage/
|   |   |-- utils/
|   |   |-- services/
|   |   |-- widgets/
|   |
|   |-- features/
|   |   |-- onboarding/
|   |   |-- home/
|   |   |-- shop/
|   |   |-- collections/
|   |   |-- search/
|   |   |-- product/
|   |   |-- cart/
|   |   |-- checkout/
|   |   |-- account/
|   |   |-- orders/
|   |   |-- wishlist/
|   |   |-- notifications/
|   |   |-- reviews/
|   |   |-- returns/
|   |   |-- recommendations/
|   |   |-- ugc/
|   |   |-- support/
|   |
|   |-- integrations/
|       |-- shopify/
|       |-- firebase/
|       |-- klaviyo/
|       |-- backend/
|
|-- assets/
|   |-- images/
|   |-- icons/
|   |-- fonts/
|   |-- animations/
|
|-- test/
|-- integration_test/
|-- android/
|-- ios/
|-- docs/
|-- pubspec.yaml
```

## Architecture Principles

Future production implementation should follow:

- Feature-based modular structure
- Reusable shared components
- Clear presentation/domain/data separation where useful
- Dependency injection where justified
- Repository/service abstraction where useful
- Centralized error handling
- Centralized network handling
- Secure local storage
- Structured navigation
- Scalable state management
- Testable business logic
- Minimal coupling
- No giant files
- No giant all-purpose services
- No duplicate API logic
- Cross-platform Android/iOS compatibility

Do not over-engineer the temporary setup-verification project.

## Design Readiness

Future FLEXWOLF UI must:

- Take visual/brand direction from flexwolf.co
- Feel native on mobile
- Not be a website wrapped inside an app
- Not use a full WebView for normal application UI
- Support premium apparel/ecommerce visual quality
- Use reusable design tokens
- Support custom fonts
- Support brand colors
- Support consistent spacing
- Support icons
- Support loading states
- Support empty states
- Support error states
- Support animations
- Support smooth transitions
- Support haptics where appropriate

Phase 1 does not build the actual design system.

## Accessibility Readiness

Future accessibility requirements:

- VoiceOver
- TalkBack
- Semantic labels
- Reasonable touch targets
- Text scaling
- Contrast
- Accessible forms
- Accessible loading states
- Accessible empty states
- Accessible error states

Phase 1 does not implement complete accessibility screens.

## Performance Readiness

Future performance requirements:

- Fast startup
- Fast product loading
- Smooth scrolling
- Lazy loading
- Image optimization
- Caching
- Pagination
- Controlled video loading
- API caching where appropriate
- Responsive animations
- No avoidable UI freezes
- Sensible weak-network behavior

## Security Readiness

Future security requirements:

- HTTPS
- Secure authentication
- API authentication
- Secure token storage
- iOS Keychain
- Android Keystore
- No plaintext passwords
- No private API keys in Flutter
- No Shopify Admin secret in Flutter
- No Klaviyo private key in Flutter
- Secure backend
- Secure Firebase configuration/rules

## Testing Readiness

Future test strategy should include:

- Unit tests for business logic and mappers.
- Widget tests for reusable UI and critical states.
- Integration tests for key app flows.
- Mocked Shopify/Firebase/Klaviyo/backend clients in local tests.
- No tests that create live Shopify customers, live Shopify orders, or Klaviyo production profiles/events.
- Separate smoke tests for dev/staging builds before production release.
