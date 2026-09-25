import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flexwolf/features/admin/data/admin_cms_repository.dart';
import 'package:flexwolf/features/admin/domain/admin_cms_models.dart';
import 'package:flexwolf/features/admin/domain/admin_cms_repositories.dart';
import 'package:flexwolf/features/home/domain/home_config.dart';
import 'package:flexwolf/features/home/domain/home_section_registry.dart';

class FirebaseAdminCmsRepository implements AdminHomeContentRepository {
  InMemoryAdminHomeContentRepository? _local;

  FirebaseFunctions get _functions => FirebaseFunctions.instanceFor(
    app: Firebase.app('flexwolfAdmin'),
    region: 'us-central1',
  );

  Future<InMemoryAdminHomeContentRepository> _repository() async {
    if (_local != null) return _local!;
    final response = await _functions
        .httpsCallable('homeCms')
        .call<Map<String, dynamic>>(<String, Object?>{'action': 'load'});
    final raw = response.data['draft'];
    final initial = raw is Map
        ? _decodeDraft(Map<String, dynamic>.from(raw))
        : null;
    return _local = InMemoryAdminHomeContentRepository(
      initialDraft: initial,
      publisher: _FirebaseCmsPublisher(_functions),
    );
  }

  Future<AdminHomeContentDraft> _save(
    Future<AdminHomeContentDraft> Function(InMemoryAdminHomeContentRepository)
    edit,
  ) async {
    final repository = await _repository();
    final before = await repository.loadDraft();
    final draft = await edit(repository);
    try {
      await _functions.httpsCallable('homeCms').call<void>(<String, Object?>{
        'action': 'save',
        'draft': _encodeDraft(draft),
      });
      return draft;
    } catch (_) {
      _local = InMemoryAdminHomeContentRepository(
        initialDraft: before,
        publisher: _FirebaseCmsPublisher(_functions),
      );
      rethrow;
    }
  }

  @override
  Future<AdminHomeContentDraft> loadDraft() async =>
      (await _repository()).loadDraft();
  @override
  Future<AdminHomeContentDraft> addBanner(AdminHomeContentItem item) =>
      _save((repo) => repo.addBanner(item));
  @override
  Future<AdminHomeContentDraft> updateItem(AdminHomeContentItem item) =>
      _save((repo) => repo.updateItem(item));
  @override
  Future<AdminHomeContentDraft> deleteItem(String id) =>
      _save((repo) => repo.deleteItem(id));
  @override
  Future<AdminHomeContentDraft> toggleItem(
    String id, {
    required bool enabled,
  }) => _save((repo) => repo.toggleItem(id, enabled: enabled));
  @override
  Future<AdminHomeContentDraft> reorderItem(String id, int displayOrder) =>
      _save((repo) => repo.reorderItem(id, displayOrder));
  @override
  Future<AdminHomeContentDraft> publish(String id) async =>
      (await _repository()).publish(id);
  @override
  Future<AdminHomeContentDraft> unpublish(String id) async {
    final repository = await _repository();
    final before = await repository.loadDraft();
    final draft = await repository.unpublish(id);
    try {
      await _FirebaseCmsPublisher(_functions).publish(draft);
      return draft;
    } catch (_) {
      _local = InMemoryAdminHomeContentRepository(
        initialDraft: before,
        publisher: _FirebaseCmsPublisher(_functions),
      );
      rethrow;
    }
  }

  @override
  Future<AdminHomeContentDraft> schedule(
    String id, {
    required DateTime startsAt,
    DateTime? endsAt,
  }) async {
    final repository = await _repository();
    final before = await repository.loadDraft();
    final draft = await repository.schedule(
      id,
      startsAt: startsAt,
      endsAt: endsAt,
    );
    try {
      await _FirebaseCmsPublisher(_functions).publish(draft);
      return draft;
    } catch (_) {
      _local = InMemoryAdminHomeContentRepository(
        initialDraft: before,
        publisher: _FirebaseCmsPublisher(_functions),
      );
      rethrow;
    }
  }

  @override
  Future<Map<String, Object?>> previewConfig() async =>
      (await _repository()).previewConfig();
}

class _FirebaseCmsPublisher implements AdminRemoteHomeContentPublisher {
  const _FirebaseCmsPublisher(this.functions);
  final FirebaseFunctions functions;

  @override
  Future<void> publish(AdminHomeContentDraft draft) async {
    await functions.httpsCallable('homeCms').call<void>(<String, Object?>{
      'action': 'publish',
      'draft': _encodeDraft(draft),
      'config': draft.toHomeConfig().toJson(),
    });
  }
}

Map<String, Object?> _encodeDraft(AdminHomeContentDraft draft) => {
  'updatedAt': draft.updatedAt.toUtc().toIso8601String(),
  'items': [
    for (final item in draft.items)
      {
        'id': item.id,
        'type': item.type.name,
        'title': item.title,
        'subtitle': item.subtitle,
        'body': item.body,
        'ctaText': item.ctaText,
        'status': item.status.name,
        'enabled': item.enabled,
        'displayOrder': item.displayOrder,
        'startsAt': item.startsAt?.toUtc().toIso8601String(),
        'endsAt': item.endsAt?.toUtc().toIso8601String(),
        'media': item.media == null
            ? null
            : {
                'url': item.media!.url,
                'kind': item.media!.kind.name,
                'altText': item.media!.altText,
                'mobileUrl': item.media!.mobileUrl,
                'aspectRatio': item.media!.aspectRatio,
              },
        'productReferences': item.productReferences
            .map((r) => r.toJson())
            .toList(),
        'collectionReferences': item.collectionReferences
            .map((r) => r.toJson())
            .toList(),
      },
  ],
};

AdminHomeContentDraft _decodeDraft(Map<String, dynamic> raw) {
  final items = raw['items'];
  if (items is! List) throw const FormatException('Invalid CMS draft items');
  return AdminHomeContentDraft(
    updatedAt:
        DateTime.tryParse('${raw['updatedAt']}')?.toUtc() ??
        DateTime.now().toUtc(),
    items: [
      for (final value in items)
        _decodeItem(Map<String, dynamic>.from(value as Map)),
    ],
  );
}

AdminHomeContentItem _decodeItem(Map<String, dynamic> raw) {
  final mediaRaw = raw['media'];
  final media = mediaRaw is Map ? Map<String, dynamic>.from(mediaRaw) : null;
  final type = HomeSectionType.values.byName(raw['type'] as String);
  return AdminHomeContentItem(
    id: raw['id'] as String,
    type: type,
    title: raw['title'] as String,
    subtitle: raw['subtitle'] as String?,
    body: raw['body'] as String?,
    ctaText: raw['ctaText'] as String?,
    status: AdminContentStatus.values.byName(raw['status'] as String),
    enabled: raw['enabled'] as bool,
    displayOrder: raw['displayOrder'] as int,
    startsAt: DateTime.tryParse('${raw['startsAt']}')?.toUtc(),
    endsAt: DateTime.tryParse('${raw['endsAt']}')?.toUtc(),
    media: media == null
        ? null
        : AdminMediaAsset(
            url: media['url'] as String,
            kind: AdminMediaKind.values.byName(media['kind'] as String),
            altText: media['altText'] as String?,
            mobileUrl: media['mobileUrl'] as String?,
            aspectRatio: (media['aspectRatio'] as num?)?.toDouble(),
          ),
    productReferences: ShopifyProductReference.listFromJson(
      raw['productReferences'],
    ),
    collectionReferences: ShopifyCollectionReference.listFromJson(
      raw['collectionReferences'],
    ),
  );
}
