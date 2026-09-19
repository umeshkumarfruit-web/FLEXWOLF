import 'package:flutter/foundation.dart';

@immutable
class AdminOperationMetric {
  const AdminOperationMetric({
    required this.id,
    required this.label,
    required this.valueLabel,
    required this.group,
  });

  final String id;
  final String label;
  final String valueLabel;
  final AdminOperationGroup group;
}

enum AdminOperationGroup {
  dashboard,
  support,
  returns,
  reviews,
  content,
  audit,
}

enum AdminApprovalStatus { draft, review, approved, published, archived }

enum AdminRequestBucket { open, pending, closed }

enum AdminReturnBucket { pending, approved, rejected, completed }

enum AdminReviewBucket { pending, published, hidden }

enum AdminAuditActionType {
  login,
  contentChanges,
  notificationActions,
  publishActions,
}

@immutable
class AdminContentApprovalItem {
  const AdminContentApprovalItem({
    required this.id,
    required this.title,
    required this.status,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final AdminApprovalStatus status;
  final DateTime updatedAt;
}

@immutable
class AdminSupportQueueSummary {
  const AdminSupportQueueSummary({required this.bucket, required this.count});

  final AdminRequestBucket bucket;
  final int count;
}

@immutable
class AdminReturnQueueSummary {
  const AdminReturnQueueSummary({required this.bucket, required this.count});

  final AdminReturnBucket bucket;
  final int count;
}

@immutable
class AdminReviewModerationSummary {
  const AdminReviewModerationSummary({
    required this.bucket,
    required this.count,
  });

  final AdminReviewBucket bucket;
  final int count;
}

@immutable
class AdminAuditActionSummary {
  const AdminAuditActionSummary({required this.type, required this.enabled});

  final AdminAuditActionType type;
  final bool enabled;
}

@immutable
class AdminOperationsSnapshot {
  const AdminOperationsSnapshot({
    required this.metrics,
    required this.contentApprovals,
    required this.supportQueues,
    required this.returnQueues,
    required this.reviewModeration,
    required this.auditActions,
    required this.updatedAt,
  });

  final List<AdminOperationMetric> metrics;
  final List<AdminContentApprovalItem> contentApprovals;
  final List<AdminSupportQueueSummary> supportQueues;
  final List<AdminReturnQueueSummary> returnQueues;
  final List<AdminReviewModerationSummary> reviewModeration;
  final List<AdminAuditActionSummary> auditActions;
  final DateTime updatedAt;
}
