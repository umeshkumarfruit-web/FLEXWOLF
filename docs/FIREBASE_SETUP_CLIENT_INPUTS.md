# Firebase Setup Client Inputs

Firebase app-side notification foundation is wired through FlutterFire Messaging. Live Firebase cannot be completed until the client supplies the FLEXWOLF-owned Firebase project and platform registration files.

## Required From Client

- Firebase project access for the FLEXWOLF-owned production project.
- Firebase project ID for `FIREBASE_PROJECT_ID`.
- Android Firebase app registered with package name `com.flexwolf.flexwolf`.
- Android `google-services.json` placed at `android/app/google-services.json`.
- iOS Firebase app registered with the final iOS bundle ID.
- iOS `GoogleService-Info.plist` placed at `ios/Runner/GoogleService-Info.plist`.
- APNs authentication key or certificate configured in Firebase Cloud Messaging.
- Push notification sender policy and notification channel naming approval.
- Backend endpoint for FCM token registration/removal against the customer account identity.
- Firebase Console access for validating Messaging delivery, Crashlytics, Analytics, and Remote Config if those products are approved.
- Shopify store domain and server-side Admin API access token if Firebase Functions will proxy Shopify Admin API requests.

## Current Repo Wiring

- `firebase_core` and `firebase_messaging` are declared in `pubspec.yaml`.
- `FlutterFireMessagingGateway` initializes Firebase defensively and handles missing config as not configured.
- Android Google Services Gradle plugin is registered and applied only when `android/app/google-services.json` exists, so local builds do not fail before the client supplies the file.
- No Firebase service account, private key, APNs key, server key, or secret is stored in the Flutter app.
- Firebase Functions backend is configured under `functions/` for server-side Shopify requests.
- App builds can use `API_BASE_URL=https://us-central1-flexwolf-mobile-app.cloudfunctions.net` for the current Firebase project.

## After Client Files Arrive

1. Place `google-services.json` in `android/app/`.
2. Place `GoogleService-Info.plist` in `ios/Runner/`.
3. Build with `--dart-define=FIREBASE_PROJECT_ID=<client-project-id>`.
4. Test notification permission, FCM token generation, foreground messages, background messages, terminated-app opens, and token deletion on logout.

## Firebase Functions Shopify Backend

The Flutter app must not store Shopify client secrets, Admin API tokens, or private Storefront tokens. Store them in Firebase Functions environment/secret configuration instead.

Required Functions values:

```text
SHOPIFY_STORE_DOMAIN=your-store.myshopify.com
SHOPIFY_API_KEY=your_shopify_client_id
SHOPIFY_API_SECRET=your_shopify_client_secret  # secret
SHOPIFY_SCOPES=read_products,write_products
SHOPIFY_ADMIN_ACCESS_TOKEN=your_shopify_admin_access_token  # secret
SHOPIFY_ADMIN_API_VERSION=2026-07
SHOPIFY_REVEAL_ACCESS_TOKEN=false
```

Deploy:

```text
cd functions
npm install
cd ..
firebase functions:secrets:set SHOPIFY_API_SECRET
firebase functions:secrets:set SHOPIFY_ADMIN_ACCESS_TOKEN
firebase deploy --only functions
```

Deployed base URL:

```text
https://us-central1-flexwolf-mobile-app.cloudfunctions.net
```

Initial endpoints:

```text
GET  /health
GET  /shopifyAuthStart
GET  /shopifyAuthCallback?shop=...&code=...&hmac=...
POST /shopifyGenerateAdminAccessToken
GET  /shopifyProducts?first=10
POST /shopifyAdminGraphql
```

