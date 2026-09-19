# Backup Guide

Phase 13 Chunk 4 prepares backup and recovery documentation only. It does not
copy production customer, order, product, inventory, fulfillment, payment, or
Shopify data.

Source code backup:
- Use the official FLEXWOLF Git repository as source of truth.
- Tag every production release with the version from `pubspec.yaml`.
- Keep release notes and build SHA attached to each release record.

Environment configuration backup:
- Store environment values in FLEXWOLF-controlled secret management or CI secret
  storage.
- Keep `.env`, signing files, Firebase service accounts, and provider secrets out
  of git.
- Maintain an environment mapping for development, staging, and production.

Firebase configuration backup:
- Record Firebase Project ID, Android app ID, iOS app ID, enabled services, and
  APNs setup status in the client-owned operations runbook.
- Export or document Remote Config templates through Firebase-approved tooling
  when Remote Config is production-enabled.
- Do not commit `google-services.json`, `GoogleService-Info.plist`, service
  accounts, private keys, or APNs keys unless client policy explicitly classifies
  a platform config file as safe for that repository.

Build artifact backup:
- Archive release APK/AAB artifacts from CI with version, build number, commit
  SHA, build date, and environment.
- Archive symbolication files only in secure release storage.
- Do not archive local debug builds as production release artifacts.

Recovery readiness:
- Recovery is ready only when source code is tagged, environment configuration is
  backed up, Firebase configuration is documented/backed up, build artifacts are
  archived, and no production ecommerce data has been duplicated.
