import 'package:flexwolf/features/home/domain/home_section_registry.dart';
import 'package:flutter/foundation.dart';

@immutable
class HomeConfig {
  const HomeConfig({
    required this.schemaVersion,
    required this.sections,
    required this.cache,
    this.generatedAt,
  });

  factory HomeConfig.fromJson(Map<String, Object?> json) {
    final result = HomeConfigParser.parse(json);
    if (!result.isValid || result.config == null) {
      throw FormatException(result.diagnostics.join(' '));
    }
    return result.config!;
  }

  final int schemaVersion;
  final List<HomeSectionConfig> sections;
  final HomeConfigCacheMetadata cache;
  final DateTime? generatedAt;

  List<HomeSectionConfig> activeSections(DateTime nowUtc) {
    final utcNow = nowUtc.toUtc();
    return sections
        .where(
          (section) => section.enabled && section.schedule.isActive(utcNow),
        )
        .toList(growable: false);
  }

  HomeConfig withCacheMetadata(HomeConfigCacheMetadata metadata) {
    return HomeConfig(
      schemaVersion: schemaVersion,
      sections: sections,
      cache: metadata,
      generatedAt: generatedAt,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      if (generatedAt != null)
        'generatedAt': generatedAt!.toUtc().toIso8601String(),
      'cache': cache.toJson(),
      'sections': sections.map((section) => section.toJson()).toList(),
    };
  }
}

@immutable
class HomeConfigParseResult {
  const HomeConfigParseResult({
    required this.config,
    required this.diagnostics,
    required this.unknownSections,
  });

  final HomeConfig? config;
  final List<String> diagnostics;
  final List<UnknownHomeSection> unknownSections;

  bool get isValid => config != null;
}

abstract final class HomeConfigParser {
  static HomeConfigParseResult parse(Map<String, Object?> json) {
    final diagnostics = <String>[];
    final unknownSections = <UnknownHomeSection>[];
    final schemaVersion = json['schemaVersion'];
    if (schemaVersion is! int) {
      return const HomeConfigParseResult(
        config: null,
        diagnostics: <String>['Home config schemaVersion is required.'],
        unknownSections: <UnknownHomeSection>[],
      );
    }
    if (!HomeSectionRegistry.supportsSchemaVersion(schemaVersion)) {
      return HomeConfigParseResult(
        config: null,
        diagnostics: <String>[
          'Unsupported Home schema version: $schemaVersion.',
        ],
        unknownSections: const <UnknownHomeSection>[],
      );
    }

    final sectionsJson = json['sections'];
    if (sectionsJson is! List) {
      return const HomeConfigParseResult(
        config: null,
        diagnostics: <String>['Home config sections must be a list.'],
        unknownSections: <UnknownHomeSection>[],
      );
    }

    final sections = <HomeSectionConfig>[];
    final seenIds = <String>{};
    var index = 0;
    for (final item in sectionsJson) {
      if (item is! Map<String, Object?>) {
        diagnostics.add('Home section at index $index is not an object.');
        index += 1;
        continue;
      }
      final rawId = _requiredTrimmedString(item['sectionId']);
      if (rawId != null && !seenIds.add(rawId)) {
        return HomeConfigParseResult(
          config: null,
          diagnostics: <String>['Duplicate Home section id: $rawId.'],
          unknownSections: unknownSections,
        );
      }
      final result = HomeSectionConfig.tryParse(item);
      if (result.section != null) {
        sections.add(result.section!);
      } else {
        diagnostics.addAll(result.diagnostics);
        if (result.unknownSection != null) {
          unknownSections.add(result.unknownSection!);
        }
      }
      index += 1;
    }

    sections.sort((a, b) {
      final orderComparison = a.displayOrder.compareTo(b.displayOrder);
      return orderComparison == 0 ? a.id.compareTo(b.id) : orderComparison;
    });

    return HomeConfigParseResult(
      config: HomeConfig(
        schemaVersion: schemaVersion,
        sections: List<HomeSectionConfig>.unmodifiable(sections),
        cache: HomeConfigCacheMetadata.fromJson(json['cache']),
        generatedAt: _parseOptionalUtc(json['generatedAt']),
      ),
      diagnostics: List<String>.unmodifiable(diagnostics),
      unknownSections: List<UnknownHomeSection>.unmodifiable(unknownSections),
    );
  }
}

@immutable
class HomeSectionParseResult {
  const HomeSectionParseResult({
    required this.section,
    required this.diagnostics,
    this.unknownSection,
  });

  final HomeSectionConfig? section;
  final List<String> diagnostics;
  final UnknownHomeSection? unknownSection;
}

@immutable
class HomeSectionConfig {
  const HomeSectionConfig({
    required this.id,
    required this.type,
    required this.enabled,
    required this.displayOrder,
    required this.schedule,
    required this.content,
    required this.productReferences,
    required this.collectionReferences,
    required this.analytics,
    required this.accessibility,
    this.destination,
    this.presentation,
    this.fallback,
  });

  static HomeSectionParseResult tryParse(Map<String, Object?> json) {
    final id = _requiredTrimmedString(json['sectionId']);
    final remoteType = _requiredTrimmedString(json['sectionType']);
    final order = json['displayOrder'];
    final diagnostics = <String>[];

    if (id == null) {
      diagnostics.add('Home section is missing sectionId.');
    }
    if (remoteType == null) {
      diagnostics.add(
        'Home section ${id ?? '<unknown>'} is missing sectionType.',
      );
    }
    if (order is! int) {
      diagnostics.add(
        'Home section ${id ?? '<unknown>'} has invalid displayOrder.',
      );
    }

    final sectionLabel = id ?? '<unknown>';
    if (order is int && order < 0) {
      diagnostics.add('Home section $sectionLabel has invalid displayOrder.');
    }
    if (json.containsKey('enabled') && json['enabled'] is! bool) {
      diagnostics.add('Home section $sectionLabel has invalid enabled state.');
    }

    final definition = remoteType == null
        ? null
        : HomeSectionRegistry.definitionForRemoteValue(remoteType);
    if (remoteType != null && definition == null) {
      diagnostics.add('Unknown Home section type skipped: $remoteType.');
      return HomeSectionParseResult(
        section: null,
        diagnostics: diagnostics,
        unknownSection: UnknownHomeSection(
          id: id ?? '<unknown>',
          remoteType: remoteType,
          displayOrder: order is int ? order : null,
        ),
      );
    }

    if (id == null || definition == null || order is! int) {
      return HomeSectionParseResult(section: null, diagnostics: diagnostics);
    }

    final schedule = HomeSchedule.fromJson(json);
    if (!schedule.hasValidDates) {
      diagnostics.add('Home section $id has malformed schedule dates.');
    }
    if (!schedule.isValidRange) {
      diagnostics.add('Home section $id has endsAt before startsAt.');
    }

    final content = HomeSectionContent.fromJson(json);
    final productReferences = ShopifyProductReference.listFromJson(
      json['productReferences'],
    );
    final collectionReferences = ShopifyCollectionReference.listFromJson(
      json['collectionReferences'],
    );
    final destination = HomeDestination.tryParse(json['destination']);
    if (json.containsKey('destination') && destination == null) {
      diagnostics.add('Home section $id has invalid destination.');
    }

    final hasRemoteReferenceList =
        _hasReferenceList(json['productReferences']) ||
        _hasReferenceList(json['collectionReferences']);
    if (!content.hasMeaningfulContent && !hasRemoteReferenceList) {
      diagnostics.add('Home section $id has no usable content or references.');
    }
    if (_hasReferenceList(json['productReferences']) &&
        productReferences.isEmpty) {
      diagnostics.add('Home section $id has malformed product references.');
    }
    if (_hasReferenceList(json['collectionReferences']) &&
        collectionReferences.isEmpty) {
      diagnostics.add('Home section $id has malformed collection references.');
    }

    final fatal = diagnostics.any(
      (message) =>
          message.contains('malformed schedule') ||
          message.contains('endsAt before startsAt') ||
          message.contains('invalid destination') ||
          message.contains('no usable content') ||
          message.contains('malformed product references') ||
          message.contains('malformed collection references') ||
          message.contains('invalid displayOrder') ||
          message.contains('invalid enabled state'),
    );
    if (fatal) {
      return HomeSectionParseResult(section: null, diagnostics: diagnostics);
    }

    return HomeSectionParseResult(
      section: HomeSectionConfig(
        id: id,
        type: definition.type,
        enabled: json['enabled'] is bool ? json['enabled']! as bool : true,
        displayOrder: order,
        schedule: schedule,
        content: content,
        productReferences: productReferences,
        collectionReferences: collectionReferences,
        analytics: HomeAnalyticsMetadata.fromJson(json['analytics']),
        accessibility: HomeAccessibilityMetadata.fromJson(
          json['accessibility'],
        ),
        destination: destination,
        presentation: HomePresentationMetadata.tryParse(json['presentation']),
        fallback: HomeFallbackBehavior.tryParse(json['fallback']),
      ),
      diagnostics: diagnostics,
    );
  }

  final String id;
  final HomeSectionType type;
  final bool enabled;
  final int displayOrder;
  final HomeSchedule schedule;
  final HomeSectionContent content;
  final List<ShopifyProductReference> productReferences;
  final List<ShopifyCollectionReference> collectionReferences;
  final HomeAnalyticsMetadata analytics;
  final HomeAccessibilityMetadata accessibility;
  final HomeDestination? destination;
  final HomePresentationMetadata? presentation;
  final HomeFallbackBehavior? fallback;

  String get analyticsName => HomeSectionRegistry.analyticsNameFor(type);

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'sectionId': id,
      'sectionType': HomeSectionRegistry.definitionForType(type).remoteValue,
      'enabled': enabled,
      'displayOrder': displayOrder,
      ...schedule.toJson(),
      ...content.toJson(),
      if (productReferences.isNotEmpty)
        'productReferences': productReferences
            .map((reference) => reference.toJson())
            .toList(),
      if (collectionReferences.isNotEmpty)
        'collectionReferences': collectionReferences
            .map((reference) => reference.toJson())
            .toList(),
      if (destination != null) 'destination': destination!.toJson(),
      if (presentation != null) 'presentation': presentation!.toJson(),
      if (fallback != null) 'fallback': fallback!.toJson(),
      if (analytics.values.isNotEmpty) 'analytics': analytics.values,
      if (accessibility.hasAnyLabel) 'accessibility': accessibility.toJson(),
    };
  }
}

@immutable
class HomeSectionContent {
  const HomeSectionContent({
    this.title,
    this.subtitle,
    this.body,
    this.ctaText,
    this.media,
  });

  factory HomeSectionContent.fromJson(Map<String, Object?> json) {
    return HomeSectionContent(
      title: _optionalTrimmedString(json['title']),
      subtitle: _optionalTrimmedString(json['subtitle']),
      body:
          _optionalTrimmedString(json['body']) ??
          _optionalTrimmedString(json['copy']),
      ctaText: _optionalTrimmedString(json['ctaText']),
      media: HomeMediaReference.tryParse(json['media'] ?? json['image']),
    );
  }

  final String? title;
  final String? subtitle;
  final String? body;
  final String? ctaText;
  final HomeMediaReference? media;

  bool get hasMeaningfulContent =>
      title != null ||
      subtitle != null ||
      body != null ||
      ctaText != null ||
      media != null;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (title != null) 'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (body != null) 'body': body,
      if (ctaText != null) 'ctaText': ctaText,
      if (media != null) 'media': media!.toJson(),
    };
  }
}

@immutable
class HomeMediaReference {
  const HomeMediaReference({
    required this.url,
    this.mobileUrl,
    this.altText,
    this.aspectRatio,
  });

  static HomeMediaReference? tryParse(Object? value) {
    if (value is String) {
      final url = _optionalTrimmedString(value);
      return url == null ? null : HomeMediaReference(url: url);
    }
    if (value is! Map<String, Object?>) {
      return null;
    }
    final url = _requiredTrimmedString(value['url']);
    if (url == null) {
      return null;
    }
    return HomeMediaReference(
      url: url,
      mobileUrl: _optionalTrimmedString(value['mobileUrl']),
      altText: _optionalTrimmedString(value['altText']),
      aspectRatio: _optionalNumber(value['aspectRatio']),
    );
  }

  final String url;
  final String? mobileUrl;
  final String? altText;
  final double? aspectRatio;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'url': url,
      if (mobileUrl != null) 'mobileUrl': mobileUrl,
      if (altText != null) 'altText': altText,
      if (aspectRatio != null) 'aspectRatio': aspectRatio,
    };
  }
}

@immutable
class ShopifyProductReference {
  const ShopifyProductReference({this.id, this.handle, this.variantId});

  static List<ShopifyProductReference> listFromJson(Object? value) {
    if (value is! List) {
      return const <ShopifyProductReference>[];
    }
    return value
        .map(ShopifyProductReference.tryParse)
        .whereType<ShopifyProductReference>()
        .toList(growable: false);
  }

  static ShopifyProductReference? tryParse(Object? value) {
    if (value is String) {
      final trimmed = _optionalTrimmedString(value);
      return trimmed == null ? null : ShopifyProductReference(id: trimmed);
    }
    if (value is! Map<String, Object?>) {
      return null;
    }
    final id = _optionalTrimmedString(value['id']);
    final handle = _optionalTrimmedString(value['handle']);
    if (id == null && handle == null) {
      return null;
    }
    return ShopifyProductReference(
      id: id,
      handle: handle,
      variantId: _optionalTrimmedString(value['variantId']),
    );
  }

  final String? id;
  final String? handle;
  final String? variantId;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (handle != null) 'handle': handle,
      if (variantId != null) 'variantId': variantId,
    };
  }
}

@immutable
class ShopifyCollectionReference {
  const ShopifyCollectionReference({this.id, this.handle});

  static List<ShopifyCollectionReference> listFromJson(Object? value) {
    if (value is! List) {
      return const <ShopifyCollectionReference>[];
    }
    return value
        .map(ShopifyCollectionReference.tryParse)
        .whereType<ShopifyCollectionReference>()
        .toList(growable: false);
  }

  static ShopifyCollectionReference? tryParse(Object? value) {
    if (value is String) {
      final trimmed = _optionalTrimmedString(value);
      return trimmed == null ? null : ShopifyCollectionReference(id: trimmed);
    }
    if (value is! Map<String, Object?>) {
      return null;
    }
    final id = _optionalTrimmedString(value['id']);
    final handle = _optionalTrimmedString(value['handle']);
    if (id == null && handle == null) {
      return null;
    }
    return ShopifyCollectionReference(id: id, handle: handle);
  }

  final String? id;
  final String? handle;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (id != null) 'id': id,
      if (handle != null) 'handle': handle,
    };
  }
}

@immutable
class HomeSchedule {
  const HomeSchedule({this.startsAt, this.endsAt, this.hasValidDates = true});

  factory HomeSchedule.fromJson(Map<String, Object?> json) {
    final startsAt = _parseOptionalUtc(json['startsAt']);
    final endsAt = _parseOptionalUtc(json['endsAt']);
    final hasValidDates =
        _isAbsentOrParseableDate(json['startsAt']) &&
        _isAbsentOrParseableDate(json['endsAt']);
    return HomeSchedule(
      startsAt: startsAt,
      endsAt: endsAt,
      hasValidDates: hasValidDates,
    );
  }

  final DateTime? startsAt;
  final DateTime? endsAt;
  final bool hasValidDates;

  bool get isValidRange =>
      startsAt == null || endsAt == null || startsAt!.isBefore(endsAt!);

  bool isActive(DateTime nowUtc) {
    final utcNow = nowUtc.toUtc();
    if (startsAt != null && utcNow.isBefore(startsAt!)) {
      return false;
    }
    if (endsAt != null && !utcNow.isBefore(endsAt!)) {
      return false;
    }
    return true;
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (startsAt != null) 'startsAt': startsAt!.toUtc().toIso8601String(),
      if (endsAt != null) 'endsAt': endsAt!.toUtc().toIso8601String(),
    };
  }
}

enum HomeDestinationType {
  product,
  collection,
  internalRoute,
  search,
  promotion,
  externalUrl,
  none,
}

@immutable
class HomeDestination {
  const HomeDestination({required this.type, this.value, this.query});

  static HomeDestination? tryParse(Object? value) {
    if (value is! Map<String, Object?>) {
      return null;
    }
    final typeValue = _requiredTrimmedString(value['type']);
    final type = switch (typeValue) {
      'product' => HomeDestinationType.product,
      'collection' => HomeDestinationType.collection,
      'internal_route' => HomeDestinationType.internalRoute,
      'search' => HomeDestinationType.search,
      'promotion' || 'drop' => HomeDestinationType.promotion,
      'external_url' => HomeDestinationType.externalUrl,
      'none' => HomeDestinationType.none,
      _ => null,
    };
    if (type == null) {
      return null;
    }
    final destinationValue = _optionalTrimmedString(value['value']);
    if (type != HomeDestinationType.none && destinationValue == null) {
      return null;
    }
    return HomeDestination(
      type: type,
      value: destinationValue,
      query: _stringObjectMap(value['query']),
    );
  }

  final HomeDestinationType type;
  final String? value;
  final Map<String, Object?>? query;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'type': switch (type) {
        HomeDestinationType.product => 'product',
        HomeDestinationType.collection => 'collection',
        HomeDestinationType.internalRoute => 'internal_route',
        HomeDestinationType.search => 'search',
        HomeDestinationType.promotion => 'promotion',
        HomeDestinationType.externalUrl => 'external_url',
        HomeDestinationType.none => 'none',
      },
      if (value != null) 'value': value,
      if (query != null) 'query': query,
    };
  }
}

@immutable
class HomeAnalyticsMetadata {
  const HomeAnalyticsMetadata(this.values);

  factory HomeAnalyticsMetadata.fromJson(Object? value) {
    return HomeAnalyticsMetadata(
      _stringObjectMap(value) ?? const <String, Object?>{},
    );
  }

  final Map<String, Object?> values;
}

@immutable
class HomeAccessibilityMetadata {
  const HomeAccessibilityMetadata({
    this.semanticLabel,
    this.imageAltText,
    this.ctaLabel,
  });

  factory HomeAccessibilityMetadata.fromJson(Object? value) {
    if (value is! Map<String, Object?>) {
      return const HomeAccessibilityMetadata();
    }
    return HomeAccessibilityMetadata(
      semanticLabel: _optionalTrimmedString(value['semanticLabel']),
      imageAltText: _optionalTrimmedString(value['imageAltText']),
      ctaLabel: _optionalTrimmedString(value['ctaLabel']),
    );
  }

  final String? semanticLabel;
  final String? imageAltText;
  final String? ctaLabel;

  bool get hasAnyLabel =>
      semanticLabel != null || imageAltText != null || ctaLabel != null;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (semanticLabel != null) 'semanticLabel': semanticLabel,
      if (imageAltText != null) 'imageAltText': imageAltText,
      if (ctaLabel != null) 'ctaLabel': ctaLabel,
    };
  }
}

@immutable
class HomePresentationMetadata {
  const HomePresentationMetadata(this.values);

  static HomePresentationMetadata? tryParse(Object? value) {
    final map = _stringObjectMap(value);
    return map == null ? null : HomePresentationMetadata(map);
  }

  final Map<String, Object?> values;

  Map<String, Object?> toJson() => values;
}

@immutable
class HomeFallbackBehavior {
  const HomeFallbackBehavior({required this.hideWhenEmpty, this.emptyMessage});

  static HomeFallbackBehavior? tryParse(Object? value) {
    if (value is! Map<String, Object?>) {
      return null;
    }
    return HomeFallbackBehavior(
      hideWhenEmpty: value['hideWhenEmpty'] is bool
          ? value['hideWhenEmpty']! as bool
          : true,
      emptyMessage: _optionalTrimmedString(value['emptyMessage']),
    );
  }

  final bool hideWhenEmpty;
  final String? emptyMessage;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'hideWhenEmpty': hideWhenEmpty,
      if (emptyMessage != null) 'emptyMessage': emptyMessage,
    };
  }
}

@immutable
class HomeConfigCacheMetadata {
  const HomeConfigCacheMetadata({this.version, this.cachedAt});

  factory HomeConfigCacheMetadata.fromJson(Object? value) {
    if (value is! Map<String, Object?>) {
      return const HomeConfigCacheMetadata();
    }
    return HomeConfigCacheMetadata(
      version: _optionalTrimmedString(value['version']),
      cachedAt: _parseOptionalUtc(value['cachedAt']),
    );
  }

  final String? version;
  final DateTime? cachedAt;

  HomeConfigCacheMetadata refreshed(DateTime nowUtc) {
    return HomeConfigCacheMetadata(
      version: version ?? 'schema-${HomeSectionRegistry.currentSchemaVersion}',
      cachedAt: nowUtc.toUtc(),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      if (version != null) 'version': version,
      if (cachedAt != null) 'cachedAt': cachedAt!.toUtc().toIso8601String(),
    };
  }
}

abstract interface class Clock {
  DateTime nowUtc();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}

String? _requiredTrimmedString(Object? value) {
  final string = _optionalTrimmedString(value);
  return string == null || string.isEmpty ? null : string;
}

String? _optionalTrimmedString(Object? value) {
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

double? _optionalNumber(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return null;
}

DateTime? _parseOptionalUtc(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    return null;
  }
  return DateTime.tryParse(value)?.toUtc();
}

bool _isAbsentOrParseableDate(Object? value) {
  if (value == null) {
    return true;
  }
  if (value is! String || value.trim().isEmpty) {
    return false;
  }
  return DateTime.tryParse(value) != null;
}

bool _hasReferenceList(Object? value) {
  return value is List && value.isNotEmpty;
}

Map<String, Object?>? _stringObjectMap(Object? value) {
  if (value is! Map) {
    return null;
  }
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    final key = entry.key;
    if (key is String) {
      result[key] = entry.value as Object?;
    }
  }
  return result;
}
