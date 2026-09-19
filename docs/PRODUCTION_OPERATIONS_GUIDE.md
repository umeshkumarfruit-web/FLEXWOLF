# Production Operations Guide

Phase 13 finalizes the production operations and monitoring foundation. It does
not add business features, execute release actions, or configure client-owned
production services.

Operational health checks:
- Startup: monitored through startup failure and startup time events.
- Authentication: monitored through authentication failure events and secure
  token/session boundaries.
- API connectivity: monitored through API failure, timeout, latency, and retry
  success events.
- Shopify connectivity: protected by HTTPS Storefront boundaries, timeout/error
  mapping, and client-dependency fallback when live config is absent.
- Firebase connectivity: Firebase Messaging, Crashlytics, Analytics, and Remote
  Config remain behind explicit boundaries; unavailable production Firebase is a
  CLIENT DEPENDENCY.
- Notification delivery: token registration, delivery, open, and navigation
  monitoring hooks are prepared; live delivery validation requires production FCM.

Monitoring ownership:
- Crash reports must be reviewed in client-owned Firebase Crashlytics once live
  configuration is supplied.
- Analytics events must use validated event names and safe bounded parameters.
- Error logs must not include secrets, tokens, private keys, payment data, or raw
  request bodies.
- Performance metrics cover startup time, API latency, memory usage, and image
  cache state.
- Duplicate monitoring is suppressed with bounded in-memory keys.

Release operations:
- Version and build number are sourced from `pubspec.yaml`.
- APK and AAB are generated through Flutter/Gradle release builds.
- Signed store release remains blocked until client signing assets are supplied.
- Rollback and backup procedures are documented but not executed by the app.

Production checklist:
- Confirm production Firebase project and platform files.
- Confirm Shopify production Storefront, Customer Account, Cart, and Checkout
  configuration.
- Confirm backend endpoints for admin, support, notification token sync,
  maintenance, update policy, and incident persistence.
- Confirm Android/iOS signing assets and store access.
- Confirm monitoring dashboards, alert thresholds, escalation owners, and support
  SLA.
