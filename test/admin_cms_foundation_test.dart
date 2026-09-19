import 'package:flexwolf/app/config/app_config.dart';
import 'package:flexwolf/app/config/app_environment.dart';
import 'package:flexwolf/features/admin/data/admin_cms_repository.dart';
import 'package:flexwolf/features/admin/data/admin_providers.dart';
import 'package:flexwolf/features/admin/domain/admin_cms_models.dart';
import 'package:flexwolf/features/admin/domain/admin_cms_repositories.dart';
import 'package:flexwolf/features/admin/presentation/admin_dashboard_screen.dart';
import 'package:flexwolf/features/home/domain/home_config.dart';
import 'package:flexwolf/features/home/domain/home_section_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CMS draft includes all required Home management surfaces', () async {
    final repository = InMemoryAdminHomeContentRepository(
      publisher: const _NoopPublisher(),
    );

    final draft = await repository.loadDraft();

    expect(
      draft.items.map((item) => item.title),
      containsAll(<String>[
        'Hero Banner',
        'Featured Collections',
        'Promotional Cards',
        'Announcement Bar',
        'Featured Products',
        'New Arrivals',
        'Best Sellers',
        'Sale Section',
        'Video Banner',
        'Footer Content',
      ]),
    );
    expect(
      draft.items
          .firstWhere((item) => item.title == 'Featured Collections')
          .collectionReferences,
      isNotEmpty,
    );
  });

  test(
    'banner management supports add edit disable reorder and preview',
    () async {
      final repository = InMemoryAdminHomeContentRepository(
        publisher: const _NoopPublisher(),
      );
      const banner = AdminHomeContentItem(
        id: 'new-banner',
        type: HomeSectionType.mainHeroBanner,
        title: 'Launch Banner',
        status: AdminContentStatus.draft,
        enabled: false,
        displayOrder: 20,
      );

      await repository.addBanner(banner);
      await repository.updateItem(banner.copyWith(title: 'Edited Banner'));
      await repository.toggleItem('new-banner', enabled: true);
      await repository.reorderItem('new-banner', 1);
      final preview = await repository.previewConfig();
      final parsed = HomeConfigParser.parse(preview);

      expect(parsed.isValid, isTrue);
      expect(parsed.config!.sections.first.id, 'new-banner');
      expect(parsed.config!.sections.first.content.title, 'Edited Banner');
    },
  );

  test(
    'content scheduling and publishing preserve client dependency boundary',
    () async {
      final dependencyRepository = InMemoryAdminHomeContentRepository();
      await expectLater(
        dependencyRepository.publish('hero-banner'),
        throwsA(isA<Exception>()),
      );

      final repository = InMemoryAdminHomeContentRepository(
        publisher: const _NoopPublisher(),
      );
      final startsAt = DateTime.utc(2026, 9, 10);
      await repository.schedule('hero-banner', startsAt: startsAt);
      final scheduled = await repository.loadDraft();

      expect(scheduled.items.first.status, AdminContentStatus.scheduled);
      await repository.publish('hero-banner');
      final published = await repository.loadDraft();

      expect(published.items.first.status, AdminContentStatus.published);
      expect(published.items.first.enabled, isTrue);
    },
  );

  testWidgets('admin Content navigation opens CMS management module', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            AppConfig.forEnvironment(AppEnvironment.development),
          ),
          adminHomeContentRepositoryProvider.overrideWithValue(
            InMemoryAdminHomeContentRepository(
              publisher: const _NoopPublisher(),
            ),
          ),
        ],
        child: const MaterialApp(home: AdminDashboardScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Content').last);
    await tester.pumpAndSettle();

    expect(find.text('Add Banner'), findsOneWidget);
    expect(find.text('Preview Home Config'), findsOneWidget);
    expect(find.text('Hero Banner'), findsWidgets);
  });
}

class _NoopPublisher implements AdminRemoteHomeContentPublisher {
  const _NoopPublisher();

  @override
  Future<void> publish(AdminHomeContentDraft draft) async {}
}
