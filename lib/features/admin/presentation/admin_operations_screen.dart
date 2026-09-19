import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/widgets/app_empty_state.dart';
import 'package:flexwolf/core/widgets/app_error_state.dart';
import 'package:flexwolf/core/widgets/app_loading_indicator.dart';
import 'package:flexwolf/features/admin/data/admin_providers.dart';
import 'package:flexwolf/features/admin/domain/admin_operations_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminOperationsScreen extends ConsumerWidget {
  const AdminOperationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(adminOperationsSnapshotProvider);
    return Semantics(
      label: 'Admin operations management',
      explicitChildNodes: true,
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminOperationsSnapshotProvider),
        child: snapshot.when(
          loading: () => ListView(
            padding: EdgeInsets.all(AppSpacing.lg),
            children: [
              AppSkeletonLoader(height: 96),
              SizedBox(height: AppSpacing.md),
              AppSkeletonLoader(height: 180),
              SizedBox(height: AppSpacing.md),
              AppSkeletonLoader(height: 180),
            ],
          ),
          error: (error, stackTrace) => ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              AppErrorState(
                error: error is AppException
                    ? error
                    : mapUnknownException(error),
                onRetry: () => ref.invalidate(adminOperationsSnapshotProvider),
              ),
            ],
          ),
          data: (data) {
            if (data.metrics.isEmpty &&
                data.contentApprovals.isEmpty &&
                data.supportQueues.isEmpty &&
                data.returnQueues.isEmpty &&
                data.reviewModeration.isEmpty) {
              return ListView(
                padding: EdgeInsets.all(AppSpacing.lg),
                children: [
                  AppEmptyState(
                    title: 'No operations data',
                    message: 'Operations data appears when backend integrations are configured.',
                    icon: Icons.admin_panel_settings_outlined,
                  ),
                ],
              );
            }
            return ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                Text(
                  'Operations',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: AppSpacing.lg),
                _MetricWrap(metrics: data.metrics),
                const SizedBox(height: AppSpacing.xl),
                _ApprovalSection(items: data.contentApprovals),
                const SizedBox(height: AppSpacing.xl),
                _QueueSection<AdminSupportQueueSummary>(
                  title: 'Support Management',
                  items: data.supportQueues,
                  labelFor: (item) => _requestBucketLabel(item.bucket),
                  countFor: (item) => item.count,
                  semanticPrefix: 'Support requests',
                ),
                const SizedBox(height: AppSpacing.xl),
                _QueueSection<AdminReturnQueueSummary>(
                  title: 'Returns Management',
                  items: data.returnQueues,
                  labelFor: (item) => _returnBucketLabel(item.bucket),
                  countFor: (item) => item.count,
                  semanticPrefix: 'Returns',
                ),
                const SizedBox(height: AppSpacing.xl),
                _QueueSection<AdminReviewModerationSummary>(
                  title: 'Review Moderation',
                  items: data.reviewModeration,
                  labelFor: (item) => _reviewBucketLabel(item.bucket),
                  countFor: (item) => item.count,
                  semanticPrefix: 'Reviews',
                ),
                const SizedBox(height: AppSpacing.xl),
                _AuditSection(actions: data.auditActions),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MetricWrap extends StatelessWidget {
  const _MetricWrap({required this.metrics});

  final List<AdminOperationMetric> metrics;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.md,
    runSpacing: AppSpacing.md,
    children: [
      for (final metric in metrics)
        Semantics(
          label: '${metric.label}: ${metric.valueLabel}',
          child: SizedBox(
            width: MediaQuery.sizeOf(context).width >= 900
                ? 220
                : double.infinity,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.divider),
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric.label,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      metric.valueLabel,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
    ],
  );
}

class _ApprovalSection extends StatelessWidget {
  const _ApprovalSection({required this.items});

  final List<AdminContentApprovalItem> items;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Content Approval', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppSpacing.sm),
      for (final item in items)
        Semantics(
          label: '${item.title} approval status ${_approvalLabel(item.status)}',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            minVerticalPadding: AppSpacing.sm,
            leading: Icon(_approvalIcon(item.status)),
            title: Text(item.title),
            subtitle: Text(_approvalLabel(item.status)),
          ),
        ),
    ],
  );
}

class _QueueSection<T> extends StatelessWidget {
  const _QueueSection({
    required this.title,
    required this.items,
    required this.labelFor,
    required this.countFor,
    required this.semanticPrefix,
  });

  final String title;
  final List<T> items;
  final String Function(T item) labelFor;
  final int Function(T item) countFor;
  final String semanticPrefix;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppSpacing.sm),
      for (final item in items)
        Semantics(
          label: '$semanticPrefix ${labelFor(item)} ${countFor(item)}',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            minVerticalPadding: AppSpacing.sm,
            title: Text(labelFor(item)),
            trailing: Text('${countFor(item)}'),
          ),
        ),
    ],
  );
}

class _AuditSection extends StatelessWidget {
  const _AuditSection({required this.actions});

  final List<AdminAuditActionSummary> actions;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Audit Log', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppSpacing.sm),
      for (final action in actions)
        Semantics(
          label:
              '${_auditLabel(action.type)} audit ${action.enabled ? 'enabled' : 'disabled'}',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            minVerticalPadding: AppSpacing.sm,
            leading: Icon(
              action.enabled ? Icons.check_circle_outline : Icons.block,
            ),
            title: Text(_auditLabel(action.type)),
            subtitle: Text(
              action.enabled
                  ? 'Tracked by reusable audit repository'
                  : 'Disabled',
            ),
          ),
        ),
    ],
  );
}

String _approvalLabel(AdminApprovalStatus status) => switch (status) {
  AdminApprovalStatus.draft => 'Draft',
  AdminApprovalStatus.review => 'Review',
  AdminApprovalStatus.approved => 'Approved',
  AdminApprovalStatus.published => 'Published',
  AdminApprovalStatus.archived => 'Archived',
};

IconData _approvalIcon(AdminApprovalStatus status) => switch (status) {
  AdminApprovalStatus.draft => Icons.edit_note_outlined,
  AdminApprovalStatus.review => Icons.rate_review_outlined,
  AdminApprovalStatus.approved => Icons.verified_outlined,
  AdminApprovalStatus.published => Icons.public_outlined,
  AdminApprovalStatus.archived => Icons.archive_outlined,
};

String _requestBucketLabel(AdminRequestBucket bucket) => switch (bucket) {
  AdminRequestBucket.open => 'Open Requests',
  AdminRequestBucket.pending => 'Pending Requests',
  AdminRequestBucket.closed => 'Closed Requests',
};

String _returnBucketLabel(AdminReturnBucket bucket) => switch (bucket) {
  AdminReturnBucket.pending => 'Pending Returns',
  AdminReturnBucket.approved => 'Approved',
  AdminReturnBucket.rejected => 'Rejected',
  AdminReturnBucket.completed => 'Completed',
};

String _reviewBucketLabel(AdminReviewBucket bucket) => switch (bucket) {
  AdminReviewBucket.pending => 'Pending Reviews',
  AdminReviewBucket.published => 'Published Reviews',
  AdminReviewBucket.hidden => 'Hidden Reviews',
};

String _auditLabel(AdminAuditActionType type) => switch (type) {
  AdminAuditActionType.login => 'Login',
  AdminAuditActionType.contentChanges => 'Content Changes',
  AdminAuditActionType.notificationActions => 'Notification Actions',
  AdminAuditActionType.publishActions => 'Publish Actions',
};
