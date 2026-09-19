import 'package:flexwolf/features/admin/domain/admin_cms_models.dart';

abstract interface class AdminHomeContentRepository {
  Future<AdminHomeContentDraft> loadDraft();
  Future<AdminHomeContentDraft> addBanner(AdminHomeContentItem item);
  Future<AdminHomeContentDraft> updateItem(AdminHomeContentItem item);
  Future<AdminHomeContentDraft> deleteItem(String id);
  Future<AdminHomeContentDraft> toggleItem(String id, {required bool enabled});
  Future<AdminHomeContentDraft> reorderItem(String id, int displayOrder);
  Future<AdminHomeContentDraft> publish(String id);
  Future<AdminHomeContentDraft> unpublish(String id);
  Future<AdminHomeContentDraft> schedule(
    String id, {
    required DateTime startsAt,
    DateTime? endsAt,
  });
  Future<Map<String, Object?>> previewConfig();
}

abstract interface class AdminRemoteHomeContentPublisher {
  Future<void> publish(AdminHomeContentDraft draft);
}

abstract interface class AdminMediaUploadGateway {
  Future<String> prepareUploadUrl({required String fileName});
}
