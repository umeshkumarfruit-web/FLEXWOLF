# Release Maintenance Guide

Phase 13 Chunk 4 prepares release maintenance, hotfix, rollback, backup, and
recovery foundations only. It does not execute a rollback, publish a release, add
new business features, or change customer UI.

Release strategy:
- Emergency hotfix: production defect or outage fix, smallest possible patch,
  expedited review, monitoring owner assigned before rollout.
- Patch release: bug fix or maintenance update with no new business behavior.
- Minor release: compatible feature or workflow release after full QA and release
  notes approval.
- Major release: breaking workflow, platform, account, backend, or provider
  change requiring migration and rollback plan review.

Release checklist:
- Version: sourced only from `pubspec.yaml` using `MAJOR.MINOR.PATCH+BUILD`.
- Build number: incremented for each store submission.
- Changelog: prepared from accepted work only.
- Release notes: prepared from `.github/release_notes_template.md`.
- Environment: production config must have production side effects enabled and
  verbose logging disabled.
- Signing readiness: Android keystore and iOS signing assets must remain outside
  source control and be supplied through local config or CI secrets.

Validation gate:
- `flutter analyze`
- `flutter test`
- `flutter build apk --release`
- `flutter build appbundle`

Performance/reliability checks:
- Release build must complete without compile failure.
- Startup, memory, image cache, API latency, and failure signals remain covered by
  Phase 13 monitoring and optimization foundations.
- Live API reliability verification remains client-dependent until production
  Shopify/backend/Firebase access is supplied.

Security:
- No Firebase service account, Shopify private token, backend credential, signing
  key, provisioning profile, or debug endpoint belongs in source control.
- `.gitignore` protects known local secret and signing file patterns.
