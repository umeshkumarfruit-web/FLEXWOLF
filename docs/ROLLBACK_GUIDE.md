# Rollback Guide

Rollback is prepared as a documented production operation. This chunk does not
execute rollback.

Android release rollback:
1. Confirm severity, customer impact, and rollback owner.
2. Pause staged rollout in Google Play Console if rollout is active.
3. If available, promote the previous stable release track or halt the current
   rollout according to Play Console capabilities.
4. Verify crash rate, startup health, checkout health, and support volume after
   rollback action.
5. Open a hotfix branch from the last stable tag if code correction is required.
6. Publish post-rollback notes to support and operations owners.

Backend rollback:
1. Identify the last stable backend deployment/version.
2. Confirm database/schema compatibility before switching traffic.
3. Restore previous deployment through the approved backend platform.
4. Do not restore or duplicate Shopify source-of-truth ecommerce data into a
   custom database.
5. Verify API latency, authentication, checkout, support, and notification token
   endpoints after rollback.

Firebase configuration rollback:
1. Identify the last approved Remote Config / Cloud Messaging / Analytics config.
2. Revert only client-owned Firebase configuration values, not app source code.
3. Validate maintenance mode, update policy, notification routing, and analytics
   event delivery after the change.
4. Keep Firebase service accounts and private keys outside Flutter source.

Approval requirements:
- Rollback requires product/operations approval unless the release owner has
  emergency authority.
- Rollback actions must be timestamped and linked to an incident record.
