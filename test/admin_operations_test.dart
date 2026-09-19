import 'package:flexwolf/core/connectivity/connectivity_service.dart';
import 'package:flexwolf/features/admin/data/admin_operations_repository.dart';
import 'package:flexwolf/features/admin/data/admin_providers.dart';
import 'package:flexwolf/features/admin/domain/admin_operations_models.dart';
import 'package:flexwolf/features/admin/presentation/admin_operations_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  test(
    'admin operations snapshot covers Phase 10.4 queues and metrics',
    () async {
      final repository = CachedAdminOperationsRepository(
        connectivity: _CountingConnectivity(),
      );

      final snapshot = await repository.fetchSnapshot();

      expect(
        snapshot.metrics.map((metric) => metric.id),
        containsAll(<String>[
          'active_users',
          'orders',
          'revenue',
          'returns',
          'reviews',
          'notifications',
          'support_tickets',
          'system_health',
        ]),
      );
      expect(
        snapshot.contentApprovals.map((item) => item.status),
        containsAll(AdminApprovalStatus.values),
      );
      expect(
        snapshot.supportQueues.map((item) => item.bucket),
        containsAll(AdminRequestBucket.values),
      );
      expect(
        snapshot.returnQueues.map((item) => item.bucket),
        containsAll(AdminReturnBucket.values),
      );
      expect(
        snapshot.reviewModeration.map((item) => item.bucket),
        containsAll(AdminReviewBucket.values),
      );
      expect(
        snapshot.auditActions.map((item) => item.type),
        containsAll(AdminAuditActionType.values),
      );
    },
  );

  test(
    'admin operations repository caches duplicate snapshot requests',
    () async {
      final connectivity = _CountingConnectivity();
      final repository = CachedAdminOperationsRepository(
        connectivity: connectivity,
      );

      final first = repository.fetchSnapshot();
      final second = repository.fetchSnapshot();
      await Future.wait(<Future<AdminOperationsSnapshot>>[first, second]);
      await repository.fetchSnapshot();

      expect(connectivity.calls, 1);
    },
  );

  testWidgets('admin operations screen renders management sections', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminOperationsRepositoryProvider.overrideWithValue(
            CachedAdminOperationsRepository(
              connectivity: _CountingConnectivity(),
            ),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: AdminOperationsScreen())),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Operations'), findsOneWidget);
    expect(find.text('Support Management'), findsOneWidget);
    expect(find.text('Returns Management'), findsOneWidget);
    expect(find.text('Review Moderation'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Audit Log'), 300);
    expect(find.text('Audit Log'), findsOneWidget);
  });
}

class _CountingConnectivity implements ConnectivityService {
  var calls = 0;

  @override
  Future<ConnectivitySnapshot> current() async {
    calls += 1;
    return const ConnectivitySnapshot(quality: ConnectivityQuality.online);
  }

  @override
  Stream<ConnectivitySnapshot> watch() => const Stream.empty();
}
