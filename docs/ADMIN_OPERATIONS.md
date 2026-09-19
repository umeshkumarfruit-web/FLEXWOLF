# Admin Operations - Phase 10 Chunk 4

Phase 10.4 adds the Admin Operations foundation on top of the existing Admin Portal, CMS, Notifications, Support, Returns, and Reviews architecture.

## Dashboard

The dashboard now exposes production-readiness summary cards for:

- Active Users
- Orders
- Revenue
- Returns
- Reviews
- Notifications
- Support Tickets
- System Health

Live metrics remain architecture placeholders until backend aggregation is available. The operations repository caches the current snapshot and coalesces duplicate requests.

## Moderation and Queues

Admin Operations prepares reusable surfaces for:

- Content Approval: Draft, Review, Approved, Published, Archived
- Support Management: Open Requests, Pending Requests, Closed Requests
- Returns Management: Pending Returns, Approved, Rejected, Completed
- Review Moderation: Pending Reviews, Published Reviews, Hidden Reviews

No content is automatically published. Review moderation and return updates use provider-independent repository hooks for future backend, Redo, and review-provider adapters.

## System Health

The status-only system health surface covers Shopify, Firebase, Backend, Klaviyo, and Gorgias. Credential editing is intentionally out of scope.

## Audit Log

The reusable audit foundation covers Login, Content Changes, Notification Actions, and Publish Actions. Full history and export workflows remain future scope.

## Analytics

Chunk 4 allows only existing admin analytics plus:

- `admin_dashboard_viewed`
- `content_published`
- `review_moderated`
- `return_updated`

No duplicate tracking was added.

## Client Dependencies

- Backend metrics aggregation for users, orders, revenue, notifications, support, returns, and reviews.
- Gorgias account/API contract for support queue data.
- Redo account/API contract for return status updates.
- Review provider moderation API contract and credentials.
- Firebase/Klaviyo production configuration for notification and marketing status.
- Client approval for admin role permissions and content approval policy.

## Phase 10 Final Readiness

Admin Operations remains provider-independent. Support, returns, review moderation, notification actions, and publish actions expose reusable admin contracts and placeholders only; no live provider credentials or private API calls are embedded in Flutter.
