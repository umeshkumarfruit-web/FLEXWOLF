FLEXWOLF - Admin and Mobile Operations Guide
Updated 22 September 2026

CURRENT DELIVERY
Customer sign up, login and logout use Firebase Authentication in the mobile app.
An account is required before adding a product to the bag or opening checkout.
Shopify Checkout Kit opens payment inside the Android app. The iOS bridge is pending.
Loox review writing opens the official Loox product form inside an app WebView.
Loox APIs are read-only, so native API submission and moderation are unavailable.

ADMIN LOGIN SETUP
1. Enable Email/Password in Firebase Authentication and create the admin user.
2. From a trusted computer with Firebase Admin SDK credentials, run:
   cd functions
   node grant_admin.js admin@example.com
3. The script grants the custom claim admin=true. Sign out and sign in again.
4. Open the Admin Portal in the FLEXWOLF app and enter those Firebase credentials.
5. Never put Shopify Admin secrets or a Firebase service account in the APK.

ADMIN DASHBOARD
Open Dashboard > Store. The four tabs are Products, Orders, Firebase users, Push.
Products: enter a title and positive price, then tap Create draft product.
Shopify creates a DRAFT and updates the default variant price.
Add media, inventory, options and sales channel publication in Shopify Admin.
To change a listed variant price, expand its product and tap the edit icon.
Orders: recent 30 Shopify orders show total, payment and fulfillment status.
The screen currently displays orders; fulfillment, capture, refund and cancellation
must still be performed in Shopify Admin until supported server actions exist.
Firebase users: recent first 100 Auth users are shown with UID and disabled state.
Push: enter title and message, then Send push notification. Signed-in customers
who allowed notifications and registered a token receive the FCM topic message.
Use a test message first; sending to the topic cannot be undone.

BACKEND DEPLOYMENT
Firebase Functions must be deployed to project flexwolf-mobile-app in us-central1.
The project must support Functions and Secret Manager (Blaze billing is required).
Set SHOPIFY_STORE_DOMAIN and SHOPIFY_ADMIN_API_VERSION=2026-07 for Functions.
Set the Shopify client secret as a Firebase secret:
   firebase functions:secrets:set SHOPIFY_API_SECRET
Shopify Admin tokens are generated and refreshed by Functions on the server.
The client credentials grant requires the app to act on its own organization store.
Deploy after setting the secret:
   firebase deploy --only functions
The Shopify app needs read_products, write_products and read_orders scopes.
If customer syncing is enabled, add read_customers and write_customers.
Admin actions use Firebase verified ID tokens and require admin=true custom claim.
The Shopify Admin GraphQL HTTP proxy also requires that admin token.
Shopify API client ID and secret are exchanged server-side for an Admin token.

MOBILE CHECKS
Build and launch the app on a device. Test Firebase sign up, sign in and logout.
Without an account, Add to Bag and checkout must ask for sign in.
On Android, pay with a Shopify test method and confirm Checkout Kit stays in-app.
Product reviews should open in the app WebView; Loox form uses ?ref=review.
Allow notifications, sign in, then test Push from Admin Portal.
Confirm Shopify product draft and variant price in Shopify Admin before publishing.

LIMITATIONS / REQUIRED INPUTS
The local environment currently has no Loox publicStoreId, Firebase Functions
Shopify secret, or Redo store ID/API secret. Live API verification was not possible.
Loox's Storefront and Merchant APIs cannot create or moderate reviews.
iOS checkout currently shows an unavailable error until its native bridge is added.
Redo return submission and admin return handling remain unconnected. Obtain the
Redo API base URL, auth method, return/status schema and webhook details, then
implement a secret-safe Firebase gateway. Do not put Redo secrets in Flutter.
Customer order history under Firebase auth is not linked to Shopify orders yet.
The current admin screen reads orders and payment state but cannot mutate orders.
