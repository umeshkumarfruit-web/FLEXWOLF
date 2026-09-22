# Loox API key setup

The FLEXWOLF app now opens the official Loox review form inside an in-app WebView; the customer stays in the app. Loox APIs are read-only, so submitting a review still uses the hosted Loox form. This does not need the private Merchant API key. Do not paste that key into a Dart file, .env, .env.example, functions/index.js, or an APK build option.

If a server-side Loox Merchant API feature is added, store the key in Firebase Secret Manager:

1. Open the terminal in this project folder.
2. Run:

   firebase functions:secrets:set LOOX_API_KEY --project flexwolf-mobile-app

3. When the Firebase CLI prompts for the value, paste the Loox Merchant API key there and press Enter.

The key is stored in Firebase Secret Manager, not in a project file. The Cloud Function that needs it must declare defineSecret("LOOX_API_KEY"), include it in that function's secrets option, and be deployed before it can read the value. Do not deploy a function just to store an unused key.

For native in-app ratings and reviews, a separate **publicStoreId** from Loox Settings > API Keys is needed. The Merchant API key does not contain that ID.

The key already shared in chat should be rotated in Loox before storing it for production.

Firebase reference: https://firebase.google.com/docs/functions/config-env#secret-parameters
Loox reference: https://help.loox.io/support/solutions/articles/501000356871-loox-reviews-api-and-webhooks

## Current project status

The Firebase CLI rejected secret creation because flexwolf-mobile-app is not on the Blaze plan. The Loox key was not saved. After the project owner enables Blaze billing, rerun the command above. The embedded storefront review form does not require this key.
