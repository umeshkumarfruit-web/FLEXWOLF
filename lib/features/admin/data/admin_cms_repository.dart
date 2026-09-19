import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/features/admin/domain/admin_cms_models.dart';
import 'package:flexwolf/features/admin/domain/admin_cms_repositories.dart';
import 'package:flexwolf/features/home/domain/home_config.dart';
import 'package:flexwolf/features/home/domain/home_section_registry.dart';

class InMemoryAdminHomeContentRepository implements AdminHomeContentRepository {
  InMemoryAdminHomeContentRepository({
    AdminRemoteHomeContentPublisher? publisher,
  }) : _publisher =
           publisher ?? const ClientDependencyRemoteHomeContentPublisher(),
       _draft = AdminHomeContentDraft(
         items: _defaultItems,
         updatedAt: DateTime.now().toUtc(),
       );

  final AdminRemoteHomeContentPublisher _publisher;
  AdminHomeContentDraft _draft;
  Future<AdminHomeContentDraft>? _loadRequest;

  @override
  Future<AdminHomeContentDraft> loadDraft() {
    return _loadRequest ??= Future<AdminHomeContentDraft>(() {
      _loadRequest = null;
      return _draft;
    });
  }

  @override
  Future<AdminHomeContentDraft> addBanner(AdminHomeContentItem item) async {
    if (!item.isBanner) {
      throw const AppException(
        kind: AppErrorKind.validation,
        message: 'Only banner content can be added from banner management.',
        code: 'admin_cms_invalid_banner',
      );
    }
    if (_draft.items.any((existing) => existing.id == item.id)) {
      throw const AppException(
        kind: AppErrorKind.validation,
        message: 'A content item with this id already exists.',
        code: 'admin_cms_duplicate_id',
      );
    }
    return _write([..._draft.items, item]);
  }

  @override
  Future<AdminHomeContentDraft> updateItem(AdminHomeContentItem item) async {
    final updated = _draft.items
        .map((existing) => existing.id == item.id ? item : existing)
        .toList(growable: false);
    if (!updated.any((existing) => existing.id == item.id)) {
      throw _notFound;
    }
    return _write(updated);
  }

  @override
  Future<AdminHomeContentDraft> deleteItem(String id) async {
    final updated = _draft.items.where((item) => item.id != id).toList();
    if (updated.length == _draft.items.length) throw _notFound;
    return _write(_normalizeOrder(updated));
  }

  @override
  Future<AdminHomeContentDraft> toggleItem(
    String id, {
    required bool enabled,
  }) async {
    return _update(id, (item) => item.copyWith(enabled: enabled));
  }

  @override
  Future<AdminHomeContentDraft> reorderItem(String id, int displayOrder) async {
    if (displayOrder < 1) {
      throw const AppException(
        kind: AppErrorKind.validation,
        message: 'Display order must be one or greater.',
        code: 'admin_cms_invalid_order',
      );
    }
    final sorted = _normalizeOrder(_draft.items);
    final currentIndex = sorted.indexWhere((item) => item.id == id);
    if (currentIndex == -1) throw _notFound;
    final item = sorted.removeAt(currentIndex);
    final nextIndex = displayOrder > sorted.length
        ? sorted.length
        : displayOrder - 1;
    sorted.insert(nextIndex, item);
    return _write(sorted);
  }

  @override
  Future<AdminHomeContentDraft> publish(String id) async {
    final draft = await _update(
      id,
      (item) =>
          item.copyWith(status: AdminContentStatus.published, enabled: true),
    );
    await _publisher.publish(draft);
    return draft;
  }

  @override
  Future<AdminHomeContentDraft> unpublish(String id) async {
    return _update(
      id,
      (item) =>
          item.copyWith(status: AdminContentStatus.unpublished, enabled: false),
    );
  }

  @override
  Future<AdminHomeContentDraft> schedule(
    String id, {
    required DateTime startsAt,
    DateTime? endsAt,
  }) async {
    if (endsAt != null && !startsAt.isBefore(endsAt)) {
      throw const AppException(
        kind: AppErrorKind.validation,
        message: 'Schedule end must be after start.',
        code: 'admin_cms_invalid_schedule',
      );
    }
    return _update(
      id,
      (item) => item.copyWith(
        status: AdminContentStatus.scheduled,
        enabled: true,
        startsAt: startsAt.toUtc(),
        endsAt: endsAt?.toUtc(),
      ),
    );
  }

  @override
  Future<Map<String, Object?>> previewConfig() async {
    return _draft.toHomeConfig().toJson();
  }

  Future<AdminHomeContentDraft> _update(
    String id,
    AdminHomeContentItem Function(AdminHomeContentItem item) update,
  ) async {
    var found = false;
    final updated = _draft.items
        .map((item) {
          if (item.id != id) return item;
          found = true;
          return update(item);
        })
        .toList(growable: false);
    if (!found) throw _notFound;
    return _write(updated);
  }

  AdminHomeContentDraft _write(List<AdminHomeContentItem> items) {
    _draft = AdminHomeContentDraft(
      items: List<AdminHomeContentItem>.unmodifiable(_normalizeOrder(items)),
      updatedAt: DateTime.now().toUtc(),
    );
    return _draft;
  }

  List<AdminHomeContentItem> _normalizeOrder(List<AdminHomeContentItem> items) {
    return [
      for (var index = 0; index < items.length; index++)
        items[index].copyWith(displayOrder: index + 1),
    ];
  }

  AppException get _notFound => const AppException(
    kind: AppErrorKind.unavailable,
    message: 'Content item was not found.',
    code: 'admin_cms_not_found',
    isRetryable: true,
  );
}

class ClientDependencyRemoteHomeContentPublisher
    implements AdminRemoteHomeContentPublisher {
  const ClientDependencyRemoteHomeContentPublisher();

  @override
  Future<void> publish(AdminHomeContentDraft draft) {
    throw const AppException(
      kind: AppErrorKind.unavailable,
      message: 'CLIENT DEPENDENCY: Firebase Remote Config or CMS publishing endpoint is not configured.',
      code: 'admin_cms_publish_not_configured',
      isRetryable: true,
    );
  }
}

class ClientDependencyAdminMediaUploadGateway
    implements AdminMediaUploadGateway {
  const ClientDependencyAdminMediaUploadGateway();

  @override
  Future<String> prepareUploadUrl({required String fileName}) {
    throw const AppException(
      kind: AppErrorKind.unavailable,
      message:
          'CLIENT DEPENDENCY: Secure media upload endpoint is not configured.',
      code: 'admin_media_upload_not_configured',
      isRetryable: true,
    );
  }
}

const _defaultItems = <AdminHomeContentItem>[
  AdminHomeContentItem(
    id: 'hero-banner',
    type: HomeSectionType.mainHeroBanner,
    title: 'Hero Banner',
    subtitle: 'Primary app hero placement',
    ctaText: 'Preview',
    media: AdminMediaAsset(
      url: 'https://cdn.flexwolf.co/placeholders/hero.jpg',
      kind: AdminMediaKind.image,
      altText: 'FLEXWOLF hero banner placeholder',
    ),
    status: AdminContentStatus.draft,
    enabled: false,
    displayOrder: 1,
  ),
  AdminHomeContentItem(
    id: 'announcement-bar',
    type: HomeSectionType.countdown,
    title: 'Announcement Bar',
    body: 'Draft announcement content',
    status: AdminContentStatus.draft,
    enabled: false,
    displayOrder: 2,
  ),
  AdminHomeContentItem(
    id: 'featured-collections',
    type: HomeSectionType.collection365,
    title: 'Featured Collections',
    status: AdminContentStatus.draft,
    enabled: false,
    displayOrder: 3,
    collectionReferences: <ShopifyCollectionReference>[
      ShopifyCollectionReference(handle: '365-collection'),
    ],
  ),
  AdminHomeContentItem(
    id: 'promotional-cards',
    type: HomeSectionType.limitedDrop,
    title: 'Promotional Cards',
    media: AdminMediaAsset(
      url: 'https://cdn.flexwolf.co/placeholders/promo.jpg',
      kind: AdminMediaKind.image,
      altText: 'FLEXWOLF promotional card placeholder',
    ),
    status: AdminContentStatus.draft,
    enabled: false,
    displayOrder: 4,
  ),
  AdminHomeContentItem(
    id: 'featured-products',
    type: HomeSectionType.appExclusives,
    title: 'Featured Products',
    status: AdminContentStatus.draft,
    enabled: false,
    displayOrder: 5,
  ),
  AdminHomeContentItem(
    id: 'new-arrivals',
    type: HomeSectionType.newArrivals,
    title: 'New Arrivals',
    status: AdminContentStatus.draft,
    enabled: false,
    displayOrder: 6,
  ),
  AdminHomeContentItem(
    id: 'best-sellers',
    type: HomeSectionType.bestSellers,
    title: 'Best Sellers',
    status: AdminContentStatus.draft,
    enabled: false,
    displayOrder: 7,
  ),
  AdminHomeContentItem(
    id: 'sale-section',
    type: HomeSectionType.sale,
    title: 'Sale Section',
    status: AdminContentStatus.draft,
    enabled: false,
    displayOrder: 8,
  ),
  AdminHomeContentItem(
    id: 'video-banner',
    type: HomeSectionType.shoppableVideos,
    title: 'Video Banner',
    media: AdminMediaAsset(
      url: 'video-placeholder://home-video-banner',
      kind: AdminMediaKind.videoPlaceholder,
      altText: 'Video banner placeholder',
    ),
    status: AdminContentStatus.draft,
    enabled: false,
    displayOrder: 9,
  ),
  AdminHomeContentItem(
    id: 'footer-content',
    type: HomeSectionType.memberExclusive,
    title: 'Footer Content',
    body: 'Footer content placeholder',
    status: AdminContentStatus.draft,
    enabled: false,
    displayOrder: 10,
  ),
];
