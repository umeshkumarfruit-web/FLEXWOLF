import 'package:flexwolf/app/router/route_names.dart';
import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/services/service_registry.dart';
import 'package:flexwolf/core/widgets/app_empty_state.dart';
import 'package:flexwolf/core/widgets/app_error_state.dart';
import 'package:flexwolf/core/widgets/app_loading_indicator.dart';
import 'package:flexwolf/core/widgets/flexwolf_logo.dart';
import 'package:flexwolf/features/admin/data/admin_providers.dart';
import 'package:flexwolf/features/admin/presentation/admin_cms_screen.dart';
import 'package:flexwolf/features/admin/presentation/admin_operations_screen.dart';
import 'package:flexwolf/features/admin/domain/admin_models.dart';
import 'package:flexwolf/integrations/analytics/analytics_boundary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  var _selected = AdminPortalDestination.dashboard;
  var _trackedDashboard = false;

  @override
  Widget build(BuildContext context) {
    final session = ref
        .watch(adminSessionProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final body = switch (_selected) {
      AdminPortalDestination.dashboard => _DashboardHome(
        onTrack: _trackDashboard,
      ),
      AdminPortalDestination.content => const AdminCmsScreen(),
      AdminPortalDestination.support => const AdminOperationsScreen(),
      _ => _ModulePlaceholder(destination: _selected),
    };
    return Semantics(
      label: 'Admin portal',
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      child: Scaffold(
        appBar: AppBar(
          title: const FlexwolfLogo(),
          actions: [
            if (session != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Text(_roleLabel(session.user.role)),
                ),
              ),
            IconButton(
              tooltip: 'Logout admin session',
              onPressed: _logout,
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 720) {
              return Row(
                children: [
                  NavigationRail(
                    selectedIndex: _selected.index,
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      for (final destination in AdminPortalDestination.values)
                        NavigationRailDestination(
                          icon: Icon(_destinationIcon(destination)),
                          label: Text(_destinationLabel(destination)),
                        ),
                    ],
                    onDestinationSelected: (index) => setState(
                      () => _selected = AdminPortalDestination.values[index],
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: body),
                ],
              );
            }
            return Column(
              children: [
                Expanded(child: body),
                NavigationBar(
                  selectedIndex: _selected.index,
                  destinations: [
                    for (final destination in AdminPortalDestination.values)
                      NavigationDestination(
                        icon: Icon(_destinationIcon(destination)),
                        label: _destinationLabel(destination),
                      ),
                  ],
                  onDestinationSelected: (index) => setState(
                    () => _selected = AdminPortalDestination.values[index],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _trackDashboard() {
    if (_trackedDashboard) return;
    _trackedDashboard = true;
    ref
        .read(analyticsGatewayProvider)
        .track(
          const AnalyticsEvent(name: AppAnalyticsEvents.adminDashboardViewed),
        );
  }

  Future<void> _logout() async {
    await ref.read(adminAuthRepositoryProvider).logout();
    ref.invalidate(adminSessionProvider);
    if (mounted) context.go(AppRoutes.adminLogin);
  }
}

class _DashboardHome extends ConsumerWidget {
  const _DashboardHome({required this.onTrack});

  final VoidCallback onTrack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    onTrack();
    final metrics = ref.watch(adminDashboardMetricsProvider);
    final statuses = ref.watch(adminSystemStatusProvider);
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(adminDashboardMetricsProvider);
        ref.invalidate(adminSystemStatusProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text('Dashboard', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: AppSpacing.lg),
          metrics.when(
            loading: () => const _DashboardSkeleton(),
            error: (error, stackTrace) => AppErrorState(
              error: error is AppException ? error : mapUnknownException(error),
              onRetry: () => ref.invalidate(adminDashboardMetricsProvider),
            ),
            data: (items) => _MetricGrid(metrics: items),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('System Status', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          statuses.when(
            loading: () => const AppSkeletonLoader(height: 120),
            error: (error, stackTrace) => AppErrorState(
              error: error is AppException ? error : mapUnknownException(error),
              onRetry: () => ref.invalidate(adminSystemStatusProvider),
            ),
            data: (items) => _StatusList(statuses: items),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<AdminDashboardMetric> metrics;

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) {
      return const AppEmptyState(
        title: 'No dashboard metrics',
        message: 'Admin metrics will appear when backend access is configured.',
        icon: Icons.dashboard_outlined,
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.sizeOf(context).width >= 900 ? 3 : 2,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.35,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, index) {
        final metric = metrics[index];
        return _DashboardCard(metric: metric);
      },
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.metric});

  final AdminDashboardMetric metric;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${metric.label}: ${metric.valueLabel}',
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
            Icon(_metricIcon(metric.iconName), size: AppIconSizes.lg),
            const Spacer(),
            Text(metric.label, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              metric.valueLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    ),
  );
}

class _StatusList extends StatelessWidget {
  const _StatusList({required this.statuses});

  final List<AdminSystemStatus> statuses;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final status in statuses)
        Semantics(
          label:
              '${_serviceLabel(status.service)} status ${_stateLabel(status.state)}',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(_stateIcon(status.state)),
            title: Text(_serviceLabel(status.service)),
            subtitle: Text(_stateLabel(status.state)),
          ),
        ),
    ],
  );
}

class _ModulePlaceholder extends StatelessWidget {
  const _ModulePlaceholder({required this.destination});

  final AdminPortalDestination destination;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: AppEmptyState(
        title: _destinationLabel(destination),
        message: 'Foundation navigation only. This module is not implemented in Phase 10 Chunk 4.',
        icon: _destinationIcon(destination),
      ),
    ),
  );
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) => const Column(
    children: [
      AppSkeletonLoader(height: 112),
      SizedBox(height: AppSpacing.md),
      AppSkeletonLoader(height: 112),
    ],
  );
}

enum AdminPortalDestination {
  dashboard,
  content,
  notifications,
  marketing,
  support,
  settings,
}

String _destinationLabel(AdminPortalDestination destination) =>
    switch (destination) {
      AdminPortalDestination.dashboard => 'Dashboard',
      AdminPortalDestination.content => 'Content',
      AdminPortalDestination.notifications => 'Notifications',
      AdminPortalDestination.marketing => 'Marketing',
      AdminPortalDestination.support => 'Support',
      AdminPortalDestination.settings => 'Settings',
    };

IconData _destinationIcon(AdminPortalDestination destination) =>
    switch (destination) {
      AdminPortalDestination.dashboard => Icons.dashboard_outlined,
      AdminPortalDestination.content => Icons.article_outlined,
      AdminPortalDestination.notifications => Icons.notifications_outlined,
      AdminPortalDestination.marketing => Icons.campaign_outlined,
      AdminPortalDestination.support => Icons.support_agent,
      AdminPortalDestination.settings => Icons.settings_outlined,
    };

IconData _metricIcon(String name) => switch (name) {
  'users' => Icons.people_outline,
  'orders' => Icons.receipt_long_outlined,
  'returns' => Icons.assignment_return_outlined,
  'reviews' => Icons.rate_review_outlined,
  'notifications' => Icons.notifications_outlined,
  'revenue' => Icons.attach_money_outlined,
  'support' => Icons.support_agent,
  _ => Icons.monitor_heart_outlined,
};

String _serviceLabel(AdminConnectionService service) => switch (service) {
  AdminConnectionService.shopify => 'Shopify',
  AdminConnectionService.firebase => 'Firebase',
  AdminConnectionService.backend => 'Backend',
  AdminConnectionService.klaviyo => 'Klaviyo',
  AdminConnectionService.gorgias => 'Gorgias',
};

String _stateLabel(AdminConnectionState state) => switch (state) {
  AdminConnectionState.unknown => 'Unknown',
  AdminConnectionState.connected => 'Connected',
  AdminConnectionState.degraded => 'Degraded',
  AdminConnectionState.disconnected => 'Disconnected',
};

IconData _stateIcon(AdminConnectionState state) => switch (state) {
  AdminConnectionState.connected => Icons.check_circle_outline,
  AdminConnectionState.degraded => Icons.warning_amber_outlined,
  AdminConnectionState.disconnected => Icons.cancel_outlined,
  AdminConnectionState.unknown => Icons.help_outline,
};

String _roleLabel(AdminRole role) => switch (role) {
  AdminRole.superAdmin => 'Super Admin',
  AdminRole.admin => 'Admin',
  AdminRole.contentManager => 'Content Manager',
  AdminRole.marketing => 'Marketing',
  AdminRole.support => 'Support',
};
