# Admin Portal Foundation

Phase 10 Chunk 1 adds the app-side Admin Portal foundation only. It does not implement Phase 10 Chunk 2 modules, configuration editing, Shopify Admin API calls, Firebase secret access, marketing automation writes, support ticket administration, or production backend administration.

## Scope Completed

- Admin Login screen and secure-session repository boundary.
- Secure session restore, logout, and unauthorized cleanup using the existing `SecureStorage` abstraction.
- Protected `/admin` route plus `/admin/login` route outside the customer app shell.
- Role foundation for Super Admin, Admin, Content Manager, Marketing, and Support.
- Admin dashboard foundation cards for Users, Orders, Returns, Reviews, Notifications, and System Status.
- Admin navigation foundation for Dashboard, Content, Notifications, Marketing, Support, and Settings.
- System status displays connection state only for Shopify, Firebase, Backend, and Klaviyo.
- Reusable audit log repository contract and in-memory foundation implementation for future admin actions.

## Role Architecture

Roles are modeled as `AdminRole` plus configurable `AdminRolePolicy` objects containing permission IDs. UI modules must ask policies for capabilities instead of hardcoding role checks. Default policies are app-side placeholders and should be replaced by backend-delivered policies when the admin backend is available.

## Security Notes

Admin authentication is a CLIENT DEPENDENCY until a secure backend endpoint exists. The Flutter app stores only the returned admin session through `SecureStorage`; it does not include Shopify Admin API tokens, Firebase secrets, private API keys, service account files, client secrets, or backend credentials.

## Client Dependencies

- Admin authentication endpoint and session contract.
- Backend-delivered role policy/permission contract.
- Admin dashboard metrics endpoint.
- Production system status endpoint for Shopify, Firebase, Backend, and Klaviyo.
- Audit log ingestion endpoint and retention policy.
- Client approval for admin roles, permission taxonomy, and access controls.

## Remaining Blockers

Production admin login, live metrics, real system status, persistent audit logs, and role enforcement beyond route/session validation require the client-provided admin backend contract. Chunk 2+ module implementations remain intentionally unstarted.

## Phase 10.2 CMS Extension

The Admin Portal Content destination now opens the CMS/Home Content Management foundation. Other admin destinations remain foundation navigation only until their later chunks. CMS publish, media upload, and Remote Config writes remain CLIENT DEPENDENCY behind backend/service boundaries.


## Phase 10.4 Operations Extension

Admin Operations adds dashboard summary metrics, content approval states, support queues, returns queues, review moderation summaries, Gorgias system status, and reusable audit action coverage. Live metric sources, moderation actions, return updates, and Gorgias queues remain client dependencies until backend/provider contracts are supplied.

## Phase 10 Final Review

The Admin Portal foundation is complete through Phase 10 Chunk 5. Authentication, guarded navigation, role policy foundations, dashboard status, CMS, operations summaries, notification/marketing architecture placeholders, audit foundations, and client dependency boundaries are documented. Live provider actions remain blocked by client-owned backend and third-party contracts.
