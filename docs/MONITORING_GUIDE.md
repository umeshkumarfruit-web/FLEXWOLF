# Monitoring Guide

Phase 13 Chunk 1 adds the production monitoring foundation only. It does not add
new business behavior, provider credentials, debug endpoints, or backend
administration.

Implemented foundation:
- `MonitoringGateway` centralizes app health, crash, analytics, notification,
  connectivity, and performance signals.
- `MonitoredApiClient` wraps the existing API client boundary to report API
  latency, non-2xx responses, timeout failures, and retryable API failures.
- `ValidatingAnalyticsGateway` validates event names, normalizes parameter names,
  strips unsupported parameter values, and supports duplicate suppression through
  the monitoring gateway.
- Crash reporting is routed through the existing Firebase boundary with fatal and
  non-fatal methods.
- Notification health has explicit hooks for token registration, delivery, and
  open events.
- Performance hooks exist for startup time, API latency, memory usage, and image
  cache state.

Operational signals prepared:
- Startup failures: fatal crash report plus `health_startup_failure`.
- API failures: `health_api_failure`, `health_api_timeout`, and
  `performance_api_latency`.
- Authentication failures: `health_authentication_failure`.
- Checkout failures: `health_checkout_failure`.
- Notification failures: `health_notification_failure`.
- Connectivity changes: `health_connectivity_changed`.
- Retry success: `health_retry_success`.

Security posture:
- No production Firebase, Shopify, backend, analytics, notification, or signing
  secret was added.
- No debug endpoint was added.
- Monitoring events intentionally use bounded status metadata and must not carry
  access tokens, customer tokens, payment data, private API keys, or raw request
  bodies.

Client dependencies:
- FLEXWOLF-owned Firebase production project and platform config files.
- Firebase Crashlytics package/configuration if live crash reporting is approved.
- Firebase Analytics package/configuration if live analytics delivery is approved.
- Backend endpoint for production push-token registration and delivery telemetry.
- Production observability dashboard ownership, alert thresholds, and on-call
  contacts.

Phase 13 final review:
- Duplicate monitoring suppression is bounded for long-running sessions.
- Production Firebase Crashlytics and Analytics delivery remain CLIENT DEPENDENCY
  until client-owned Firebase configuration is supplied.
- Monitoring payloads remain status-only and must not include credentials,
  payment data, customer tokens, or raw request bodies.
