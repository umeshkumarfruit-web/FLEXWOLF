# Phase 12.5 Client Dependency Report

The following items require client ownership, credentials, accounts, or approvals and cannot be completed inside the Flutter repository without exposing secrets or publishing control.

## Ownership

- GitHub repository ownership, branch protection, release approvals, and CI secrets
- Firebase production project ownership
- Shopify production store ownership
- Apple Developer account ownership
- Google Play Console ownership
- Klaviyo account ownership
- Gorgias account ownership
- Redo account ownership
- Reviews platform ownership

## Credentials And Secrets

- Android release keystore and `key.properties`, supplied outside git or through CI secrets
- Apple signing certificate, provisioning profiles, App Store Connect credentials, and APNs configuration
- Firebase `google-services.json`, `GoogleService-Info.plist`, APNs key/certificate, and service-account credentials where needed outside Flutter
- Shopify Storefront access configuration and Customer Account OAuth/PKCE settings
- Klaviyo, Gorgias, Redo, and reviews provider credentials through a secure backend or approved client-side public SDK pattern
- Backend secrets for Admin API, webhooks, support writes, returns provider calls, and protected operations

## Business And Store Inputs

- Privacy Policy URL
- Terms URL
- Store listings, screenshots, categories, ratings, support contact, compliance answers, and release notes
- Shopify products, collections, variants, inventory, prices, markets, taxes, duties, shipping, discounts, gift cards, payment methods, and order emails
- Production notification payload samples
- Production deep-link host files: Android Digital Asset Links and Apple App Site Association

## Acceptance Dependencies

- Final payment verification in Shopify production or approved test mode
- Push notification verification on real Android and iOS devices
- Deep-link verification from browser, notifications, email, and checkout redirects
- Analytics and conversion tracking verification in the selected production dashboards
- iOS final signed archive and TestFlight/App Store validation on macOS
