# Support Guide

Phase 13 Chunk 2 prepares the production support and maintenance workflow on top
of the existing Customer Support, Admin Portal, Analytics, Notifications, and
Crash Monitoring foundations.

Supported production intake types:
- Bug reports.
- Feature requests.
- Technical issues.
- General feedback.

Prepared workflow:
- `SupportWorkflowRequest` captures support type, subject, message, optional
  email, app version, and safe string context.
- `ProductionSupportWorkflowRepository` defines the submission boundary.
- `ClientDependencySupportWorkflowRepository` validates intake and marks accepted
  requests as CLIENT DEPENDENCY until FLEXWOLF provides the production ticketing
  endpoint.

Incident management foundation:
- `IncidentRecord` captures title, area, priority, status, timestamps, and
  resolution notes.
- Priorities: low, medium, high, critical.
- Statuses: open, in-progress, resolved, closed.
- `IncidentRepository` prepares logging and status update operations.

Logging readiness:
- Error, warning, and network logging continue through `AppLogger` and existing
  network boundaries.
- Production logging does not include verbose error details.
- Token, secret, key, password, API key, and bearer-token patterns are redacted
  before output.

Client dependencies:
- Secure support ticket endpoint or approved Gorgias proxy.
- Incident dashboard or backend persistence for production incident records.
- Support routing, SLA, priority definitions, owners, and escalation contacts.
- Approved maintenance/update source such as Firebase Remote Config or backend.
