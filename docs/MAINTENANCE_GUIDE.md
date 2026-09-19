# Maintenance Guide

Phase 13 Chunk 2 prepares maintenance architecture only. It does not enable a
forced update, production outage switch, read-only enforcement, or new business
feature.

Prepared foundations:
- `MaintenanceState` represents normal, banner, read-only, and outage modes.
- `MaintenanceRepository` provides the reusable boundary for future remote
  maintenance state.
- `NoopMaintenanceRepository` keeps unconfigured builds in normal mode.
- `AppUpdateState` represents current version, latest version, optional update,
  and mandatory update policy.
- `AppUpdateRepository` provides the reusable update-check boundary.

Production behavior planned behind client-controlled configuration:
- Maintenance banner for temporary operational notices.
- Read-only mode for support or provider outages where browsing can continue but
  writes should be disabled.
- Temporary outage message for unavailable critical services.
- Optional update prompt for recommended releases.
- Mandatory update prompt for unsupported releases.

Security requirements:
- Maintenance and update payloads must come from Firebase Remote Config or a
  secure backend controlled by FLEXWOLF.
- Do not store private Firebase, backend, Shopify, signing, or service-account
  credentials in Flutter.
- Do not expose debug maintenance endpoints in production builds.

Phase 13 final review:
- Maintenance and update states remain prepared but inactive by default.
- Live maintenance banner, read-only mode, outage message, optional update, and
  mandatory update require Firebase Remote Config or secure backend ownership.
