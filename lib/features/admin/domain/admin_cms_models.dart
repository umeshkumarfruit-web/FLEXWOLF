import 'package:flexwolf/features/home/domain/home_config.dart';
import 'package:flexwolf/features/home/domain/home_section_registry.dart';
import 'package:flutter/foundation.dart';

enum AdminContentStatus { draft, scheduled, published, unpublished }

enum AdminMediaKind { image, videoPlaceholder }

@immutable
class AdminMediaAsset {
  const AdminMediaAsset({
    required this.url,
    required this.kind,
    this.altText,
    this.mobileUrl,
    this.aspectRatio,
  });

  final String url;
  final AdminMediaKind kind;
  final String? altText;
  final String? mobileUrl;
  final double? aspectRatio;

  HomeMediaReference toHomeMediaReference() => HomeMediaReference(
    url: url,
    mobileUrl: mobileUrl,
    altText: altText,
    aspectRatio: aspectRatio,
  );
}

@immutable
class AdminHomeContentItem {
  const AdminHomeContentItem({
    required this.id,
    required this.type,
    required this.title,
    required this.status,
    required this.enabled,
    required this.displayOrder,
    this.subtitle,
    this.body,
    this.ctaText,
    this.media,
    this.startsAt,
    this.endsAt,
    this.productReferences = const <ShopifyProductReference>[],
    this.collectionReferences = const <ShopifyCollectionReference>[],
  });

  final String id;
  final HomeSectionType type;
  final String title;
  final String? subtitle;
  final String? body;
  final String? ctaText;
  final AdminMediaAsset? media;
  final AdminContentStatus status;
  final bool enabled;
  final int displayOrder;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final List<ShopifyProductReference> productReferences;
  final List<ShopifyCollectionReference> collectionReferences;

  bool get isBanner =>
      type == HomeSectionType.mainHeroBanner ||
      type == HomeSectionType.countdown ||
      type == HomeSectionType.shoppableVideos;

  AdminHomeContentItem copyWith({
    String? title,
    String? subtitle,
    String? body,
    String? ctaText,
    AdminMediaAsset? media,
    AdminContentStatus? status,
    bool? enabled,
    int? displayOrder,
    DateTime? startsAt,
    DateTime? endsAt,
    List<ShopifyProductReference>? productReferences,
    List<ShopifyCollectionReference>? collectionReferences,
  }) {
    return AdminHomeContentItem(
      id: id,
      type: type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      body: body ?? this.body,
      ctaText: ctaText ?? this.ctaText,
      media: media ?? this.media,
      status: status ?? this.status,
      enabled: enabled ?? this.enabled,
      displayOrder: displayOrder ?? this.displayOrder,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      productReferences: productReferences ?? this.productReferences,
      collectionReferences: collectionReferences ?? this.collectionReferences,
    );
  }

  HomeSectionConfig toHomeSection() {
    return HomeSectionConfig(
      id: id,
      type: type,
      enabled:
          enabled &&
          (status == AdminContentStatus.published ||
              status == AdminContentStatus.scheduled),
      displayOrder: displayOrder,
      schedule: HomeSchedule(startsAt: startsAt, endsAt: endsAt),
      content: HomeSectionContent(
        title: title,
        subtitle: subtitle,
        body: body,
        ctaText: ctaText,
        media: media?.toHomeMediaReference(),
      ),
      productReferences: productReferences,
      collectionReferences: collectionReferences,
      analytics: const HomeAnalyticsMetadata(<String, Object?>{}),
      accessibility: HomeAccessibilityMetadata(
        semanticLabel: title,
        imageAltText: media?.altText,
      ),
    );
  }
}

@immutable
class AdminHomeContentDraft {
  const AdminHomeContentDraft({required this.items, required this.updatedAt});

  final List<AdminHomeContentItem> items;
  final DateTime updatedAt;

  HomeConfig toHomeConfig() {
    final sections = [...items]
      ..sort(
        (a, b) => a.displayOrder == b.displayOrder
            ? a.id.compareTo(b.id)
            : a.displayOrder.compareTo(b.displayOrder),
      );
    return HomeConfig(
      schemaVersion: HomeSectionRegistry.currentSchemaVersion,
      generatedAt: updatedAt.toUtc(),
      cache: HomeConfigCacheMetadata(
        version: 'schema-${HomeSectionRegistry.currentSchemaVersion}',
        cachedAt: updatedAt.toUtc(),
      ),
      sections: sections.map((item) => item.toHomeSection()).toList(),
    );
  }
}
