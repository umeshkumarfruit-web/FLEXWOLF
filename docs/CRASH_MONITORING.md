# Crash Monitoring

Crash monitoring is prepared behind `FirebaseCrashReportingGateway`.

Current status:
- Fatal reporting contract exists through `recordFatal`.
- Non-fatal reporting contract exists through `recordNonFatal`.
- Startup failures are treated as fatal by `MonitoringGateway`.
- API, authentication, checkout, and notification failures can be reported as
  non-fatal app-health events.
- The default implementation is `FirebaseCrashReportingNotConfigured`, so local
  and unconfigured builds do not send crash data.

Client dependency:
- Live Firebase Crashlytics remains CLIENT DEPENDENCY until FLEXWOLF supplies and
  approves the production Firebase project, platform configuration files, and
  Crashlytics package setup.

Security requirements:
- Do not attach tokens, payment data, private keys, raw request bodies, or full
  customer records to crash reports.
- Production crash reporting must use client-owned Firebase access and release
  build configuration only.
