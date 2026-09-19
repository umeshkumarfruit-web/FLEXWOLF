# Firebase Notifications

Phase 8 Chunk 2 adds the FCM production-readiness foundation behind the existing Firebase boundary.

Implemented:
- Firebase messaging boundary for initialization, permission status/request, current token, token refreshes, foreground notifications, notification opens, initial terminated-app notification, and token deletion.
- Secure FCM token registration storage through SecureStorage.
- Malformed secure token registration cache is ignored safely during restore.
- Device registration, token update, restore after login, remove on logout, and duplicate registration prevention.
- Android/iOS permission architecture with denied/re-request UI state.
- Foreground/background/terminated notification handling contracts.
- Notification tap action validation against existing deep-link contract.
- Duplicate notification receive prevention.
- Accessible notification settings row in Account settings.
- Analytics limited to notification_permission, notification_received, and notification_navigation.

Client dependencies:
- FLEXWOLF-owned Firebase project.
- Android `google-services.json` and iOS `GoogleService-Info.plist` must be supplied securely by the client for live FCM. The app handles missing config as not configured.
- FlutterFire client packages are declared: `firebase_core` and `firebase_messaging`.
- APNs key/certificate setup for iOS.
- Android notification channel policy and production sender/server registration endpoint.
- Backend or approved service endpoint for associating FCM tokens with Customer Account identities.

No Firebase private credentials, Shopify Admin API token, private token, or client secret was added.
