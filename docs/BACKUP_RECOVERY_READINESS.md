# Backup And Recovery Readiness

Shopify remains the source of truth for ecommerce data: products, customers,
orders, inventory, pricing, fulfillment, tracking, collections, metafields, and
metaobjects.

Future backup/recovery requirements:

- Backend/config backups for any custom backend.
- CMS/custom database backups where applicable.
- Restore procedure documented and periodically tested.
- Secrets stored only in FLEXWOLF-controlled accounts or secret managers.
- Git tags and versioning for release checkpoints.
- No developer-owned single point of failure.
- Handover includes account ownership, deployment access, environment mapping,
  and recovery runbooks.

PostgreSQL or another database may later store only approved custom app/backend
data. It must not duplicate Shopify ecommerce source-of-truth records.
