import 'package:flexwolf/core/connectivity/connectivity_service.dart';
import 'package:flexwolf/features/admin/domain/admin_operations_models.dart';
import 'package:flexwolf/features/admin/domain/admin_operations_repositories.dart';

class CachedAdminOperationsRepository implements AdminOperationsRepository {
  CachedAdminOperationsRepository({required this.connectivity});

  final ConnectivityService connectivity;
  AdminOperationsSnapshot? _cache;
  Future<AdminOperationsSnapshot>? _inFlight;

  @override
  Future<AdminOperationsSnapshot> fetchSnapshot() {
    final cached = _cache;
    if (cached != null) return Future.value(cached);
    return _inFlight ??= _load().whenComplete(() => _inFlight = null);
  }

  Future<AdminOperationsSnapshot> _load() async {
    final status = await connectivity.current();
    final backendLabel = status.quality == ConnectivityQuality.offline
        ? 'Offline fallback'
        : 'Backend pending';
    final snapshot = AdminOperationsSnapshot(
      metrics: <AdminOperationMetric>[
        const AdminOperationMetric(
          id: 'active_users',
          label: 'Active Users',
          valueLabel: 'Backend pending',
          group: AdminOperationGroup.dashboard,
        ),
        const AdminOperationMetric(
          id: 'orders',
          label: 'Orders',
          valueLabel: 'Shopify backend pending',
          group: AdminOperationGroup.dashboard,
        ),
        const AdminOperationMetric(
          id: 'revenue',
          label: 'Revenue',
          valueLabel: 'Unavailable until backend aggregation',
          group: AdminOperationGroup.dashboard,
        ),
        const AdminOperationMetric(
          id: 'returns',
          label: 'Returns',
          valueLabel: 'Redo backend pending',
          group: AdminOperationGroup.returns,
        ),
        const AdminOperationMetric(
          id: 'reviews',
          label: 'Reviews',
          valueLabel: 'Provider pending',
          group: AdminOperationGroup.reviews,
        ),
        const AdminOperationMetric(
          id: 'notifications',
          label: 'Notifications',
          valueLabel: 'Firebase/Klaviyo pending',
          group: AdminOperationGroup.dashboard,
        ),
        const AdminOperationMetric(
          id: 'support_tickets',
          label: 'Support Tickets',
          valueLabel: 'Gorgias pending',
          group: AdminOperationGroup.support,
        ),
        AdminOperationMetric(
          id: 'system_health',
          label: 'System Health',
          valueLabel: backendLabel,
          group: AdminOperationGroup.dashboard,
        ),
      ],
      contentApprovals: _contentApprovals,
      supportQueues: _supportQueues,
      returnQueues: _returnQueues,
      reviewModeration: _reviewModeration,
      auditActions: _auditActions,
      updatedAt: DateTime.now().toUtc(),
    );
    _cache = snapshot;
    return snapshot;
  }

  @override
  Future<List<AdminContentApprovalItem>> fetchContentApprovals() async =>
      (await fetchSnapshot()).contentApprovals;

  @override
  Future<List<AdminSupportQueueSummary>> fetchSupportQueues() async =>
      (await fetchSnapshot()).supportQueues;

  @override
  Future<List<AdminReturnQueueSummary>> fetchReturnQueues() async =>
      (await fetchSnapshot()).returnQueues;

  @override
  Future<List<AdminReviewModerationSummary>> fetchReviewModeration() async =>
      (await fetchSnapshot()).reviewModeration;

  @override
  Future<void> updateReturnStatus(
    String returnId,
    AdminReturnBucket status,
  ) async {
    // Reusable hook for future Redo/backend update integration.
  }

  @override
  Future<void> moderateReview(String reviewId, AdminReviewBucket status) async {
    // Reusable hook for future provider-independent review moderation.
  }
}

final _contentApprovals = <AdminContentApprovalItem>[
  AdminContentApprovalItem(
    id: 'home-draft',
    title: 'Home content draft',
    status: AdminApprovalStatus.draft,
    updatedAt: DateTime.utc(2026, 1, 1),
  ),
  AdminContentApprovalItem(
    id: 'banner-review',
    title: 'Seasonal banner review',
    status: AdminApprovalStatus.review,
    updatedAt: DateTime.utc(2026, 1, 1),
  ),
  AdminContentApprovalItem(
    id: 'sale-approved',
    title: 'Sale section approved',
    status: AdminApprovalStatus.approved,
    updatedAt: DateTime.utc(2026, 1, 1),
  ),
  AdminContentApprovalItem(
    id: 'hero-published',
    title: 'Hero banner published',
    status: AdminApprovalStatus.published,
    updatedAt: DateTime.utc(2026, 1, 1),
  ),
  AdminContentApprovalItem(
    id: 'old-promo-archived',
    title: 'Archived promotion',
    status: AdminApprovalStatus.archived,
    updatedAt: DateTime.utc(2026, 1, 1),
  ),
];

const _supportQueues = <AdminSupportQueueSummary>[
  AdminSupportQueueSummary(bucket: AdminRequestBucket.open, count: 0),
  AdminSupportQueueSummary(bucket: AdminRequestBucket.pending, count: 0),
  AdminSupportQueueSummary(bucket: AdminRequestBucket.closed, count: 0),
];

const _returnQueues = <AdminReturnQueueSummary>[
  AdminReturnQueueSummary(bucket: AdminReturnBucket.pending, count: 0),
  AdminReturnQueueSummary(bucket: AdminReturnBucket.approved, count: 0),
  AdminReturnQueueSummary(bucket: AdminReturnBucket.rejected, count: 0),
  AdminReturnQueueSummary(bucket: AdminReturnBucket.completed, count: 0),
];

const _reviewModeration = <AdminReviewModerationSummary>[
  AdminReviewModerationSummary(bucket: AdminReviewBucket.pending, count: 0),
  AdminReviewModerationSummary(bucket: AdminReviewBucket.published, count: 0),
  AdminReviewModerationSummary(bucket: AdminReviewBucket.hidden, count: 0),
];

const _auditActions = <AdminAuditActionSummary>[
  AdminAuditActionSummary(type: AdminAuditActionType.login, enabled: true),
  AdminAuditActionSummary(
    type: AdminAuditActionType.contentChanges,
    enabled: true,
  ),
  AdminAuditActionSummary(
    type: AdminAuditActionType.notificationActions,
    enabled: true,
  ),
  AdminAuditActionSummary(
    type: AdminAuditActionType.publishActions,
    enabled: true,
  ),
];
