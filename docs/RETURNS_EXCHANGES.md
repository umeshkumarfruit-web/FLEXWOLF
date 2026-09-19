# Returns and Exchanges

Phase 9.1 adds the foundation for customer returns and exchanges.

## Supported Surface

- Return eligibility is evaluated from the existing customer order model.
- Eligible order details expose separate Return and Exchange actions.
- Return requests capture item, quantity, reason, note, confirmation, status, and history.
- Exchange requests support size and color exchange fields plus confirmation and status.
- UI states cover loading, skeleton, empty history, error, retry, and offline messaging.
- Analytics tracks only `return_started`, `return_submitted`, `exchange_started`, and `exchange_submitted`.

## Configuration

Return reasons are provided through `returnReasonsProvider` and can be replaced by remote configuration or Redo once the API contract is available. The fallback list is a configurable default, not a production source of truth.

## Redo Client Dependency

CLIENT DEPENDENCY: Redo credentials, API base URL, authentication method, webhook/event contract, and reason/status schema are not present in this repository. The app includes a reusable `RedoReturnsGateway` boundary and a client-dependency implementation that never exposes credentials or secrets in the mobile client.

Redo integration should be completed through a backend-owned gateway or other secret-safe service. Do not ship Redo private tokens, Shopify Admin API credentials, client secrets, or private API tokens in Flutter code.
## Phase 9.4 Integration Notes

- Order details remains the primary entry point for eligible Return and Exchange actions, with Contact Support and Tracking alongside order context.
- Customer Profile now exposes My Returns, backed by the shared returns repository history call, so submitted return/exchange status can be reviewed outside the order sheet.
- The Redo boundary remains reusable and credential-safe; live Redo status, labels, and webhooks remain CLIENT DEPENDENCY until the backend contract is supplied.
## Phase 9.5 Production Readiness

- Returns and exchanges were reviewed for eligibility, invalid-return handling, confirmation, status history, retry, offline, and duplicate submission behavior.
- App-side readiness is complete against the current reusable repository and Redo boundary.
- Live Redo operation remains CLIENT DEPENDENCY and must stay behind a secret-safe backend or approved proxy.

