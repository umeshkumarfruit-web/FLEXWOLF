# Client Dependency Notes

Phase 13 Chunk 1 dependencies:

| Area | Dependency | Status |
| --- | --- | --- |
| Firebase Crashlytics | Client-owned Firebase production project and Crashlytics setup | CLIENT DEPENDENCY |
| Firebase Analytics | Client-owned analytics destination and approved event taxonomy | CLIENT DEPENDENCY |
| FCM token sync | Secure backend endpoint for token registration/removal | CLIENT DEPENDENCY |
| Notification delivery | Provider dashboard or backend telemetry for delivered/opened status | CLIENT DEPENDENCY |
| Production dashboards | Alert thresholds, owners, and escalation contacts | CLIENT DEPENDENCY |

No production secrets, service accounts, private Shopify tokens, backend
credentials, signing keys, or debug endpoints were added in this chunk.

Phase 13 Chunk 2 dependencies:

| Area | Dependency | Status |
| --- | --- | --- |
| Production support intake | Secure ticket endpoint or approved Gorgias proxy | CLIENT DEPENDENCY |
| Incident management | Backend/dashboard persistence, alert ownership, and escalation policy | CLIENT DEPENDENCY |
| App update management | Client-approved latest-version source and store URLs | CLIENT DEPENDENCY |
| Maintenance mode | Firebase Remote Config or secure backend maintenance payload | CLIENT DEPENDENCY |
| Support operations | SLA, priority definitions, routing rules, and owners | CLIENT DEPENDENCY |

No production support, incident, update, maintenance, Firebase, backend, Shopify,
or Gorgias secrets were added in Chunk 2.

Phase 13 Chunk 3 dependencies:

| Area | Dependency | Status |
| --- | --- | --- |
| Production API profiling | Live Shopify/backend access and production-like traffic | CLIENT DEPENDENCY |
| Image CDN validation | Production product media and CDN headers | CLIENT DEPENDENCY |
| Push stream validation | Production Firebase/FCM setup | CLIENT DEPENDENCY |
| Performance dashboards | Client-owned monitoring dashboard thresholds | CLIENT DEPENDENCY |

No production secrets, debug endpoints, or private provider credentials were
added in Chunk 3.

Phase 13 Chunk 4 dependencies:

| Area | Dependency | Status |
| --- | --- | --- |
| Android signing | Release keystore, passwords, Play Console access, rollout owner | CLIENT DEPENDENCY |
| iOS signing | Apple Developer/App Store Connect access and signing assets | CLIENT DEPENDENCY |
| Rollback authority | Approved emergency owner and rollback approval policy | CLIENT DEPENDENCY |
| Backend recovery | Deployment platform access and previous stable release records | CLIENT DEPENDENCY |
| Firebase recovery | Client-owned Firebase project access and config history/export process | CLIENT DEPENDENCY |
| Artifact backup | Secure artifact storage with commit/version retention policy | CLIENT DEPENDENCY |

No production secrets, signing keys, Firebase service accounts, backend
credentials, or production data backups were added in Chunk 4.

Phase 13 Chunk 5 dependencies:

| Area | Dependency | Status |
| --- | --- | --- |
| Production Firebase | Crashlytics, Analytics, FCM, Remote Config project/platform setup | CLIENT DEPENDENCY |
| Shopify production | Storefront, Customer Account, Cart, Checkout, Markets, payments | CLIENT DEPENDENCY |
| Backend production | Admin, support, notification token sync, maintenance, update, incidents | CLIENT DEPENDENCY |
| Release stores | Play Console, App Store Connect, signing assets, rollout owners | CLIENT DEPENDENCY |
| Operations ownership | Monitoring dashboards, alert thresholds, SLA, escalation contacts | CLIENT DEPENDENCY |
| Live validation | Real checkout, auth, notifications, support, analytics, crash reporting | CLIENT DEPENDENCY |

No production secrets, debug endpoints, private Firebase material, private
Shopify tokens, backend credentials, signing keys, or production data exports
were added in Chunk 5.
