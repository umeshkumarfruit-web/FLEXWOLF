# Loox API key setup

Product ratings and published reviews are displayed natively using Loox's public Storefront API. Loox's Storefront and Merchant APIs are read-only, so native review submission cannot be connected to Loox with the provided Merchant API key. The app's **Write Review** button opens Loox's supported product review form (`/products/{handle}?ref=review`) in an in-app browser. Submitted reviews appear in the native list after Loox publishes them. Do not paste the Merchant API key into a Dart file, .env, .env.example, functions/index.js, or an APK build option.

If a server-side Loox Merchant API feature is added, store the key in Firebase Secret Manager:

1. Open the terminal in this project folder.
2. Run:

   firebase functions:secrets:set LOOX_API_KEY --project flexwolf-mobile-app

3. When the Firebase CLI prompts for the value, paste the Loox Merchant API key there and press Enter.

The key is stored in Firebase Secret Manager, not in a project file. The Cloud Function that needs it must declare defineSecret("LOOX_API_KEY"), include it in that function's secrets option, and be deployed before it can read the value. Do not deploy a function just to store an unused key.

For native in-app ratings and reviews, Loox's **publicStoreId** from Settings > API Keys is configured as the app's default. It may be overridden with `LOOX_PUBLIC_STORE_ID` in Flutter build configuration. The Merchant API key does not contain that ID. The configured public ID was verified against the live Storefront API using a FLEXWOLF product; ratings, review counts, and review lists returned successfully.

The key already shared in chat should be rotated in Loox before storing it for production.

Firebase reference: https://firebase.google.com/docs/functions/config-env#secret-parameters
Loox reference: https://help.loox.io/support/solutions/articles/501000356871-loox-reviews-api-and-webhooks

## Current project status

The Firebase CLI rejected secret creation because flexwolf-mobile-app is not on the Blaze plan. The Loox key was not saved. The public Storefront API does not require this key.
