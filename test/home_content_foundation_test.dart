import 'package:flexwolf/core/storage/local_storage.dart';
import 'package:flexwolf/features/home/data/default_home_content_repository.dart';
import 'package:flexwolf/features/home/data/home_content_data_sources.dart';
import 'package:flexwolf/features/home/domain/home_config.dart';
import 'package:flexwolf/features/home/domain/home_content_repository.dart';
import 'package:flexwolf/features/home/domain/home_section_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Home section registry', () {
    test('accounts for all 22 contractual Home section types', () {
      expect(HomeSectionRegistry.definitions, hasLength(22));
      expect(HomeSectionType.values, hasLength(22));
      expect(
        HomeSectionRegistry.definitions.map(
          (definition) => definition.remoteValue,
        ),
        containsAll(<String>[
          'main_hero_banner',
          'new_drop',
          'new_arrivals',
          'best_sellers',
          'trending',
          'sale',
          '365_collection',
          'flex_arm_collection',
          'shorts',
          'sweats',
          'app_exclusives',
          'recommended_for_you',
          'recently_viewed',
          'complete_the_look',
          'creator_picks',
          'athlete_picks',
          'shoppable_videos',
          'customer_ugc',
          'back_in_stock',
          'limited_drop',
          'countdown',
          'member_exclusive',
        ]),
      );
    });
  });

  group('Home config parsing and validation', () {
    test(
      'parses valid config, references, destination, metadata, and ordering',
      () {
        final result = HomeConfigParser.parse(
          _validConfig(
            sections: <Map<String, Object?>>[
              _section('late', 'new_arrivals', order: 20),
              _section(
                'hero',
                'main_hero_banner',
                order: 1,
                extra: <String, Object?>{
                  'subtitle': 'Built for daily training.',
                  'copy': 'Native configurable content.',
                  'ctaText': 'Shop now',
                  'media': <String, Object?>{
                    'url': 'https://cdn.flexwolf.co/home.jpg',
                    'mobileUrl': 'https://cdn.flexwolf.co/home-mobile.jpg',
                    'altText': 'FLEXWOLF training apparel',
                    'aspectRatio': 0.8,
                  },
                  'destination': <String, Object?>{
                    'type': 'collection',
                    'value': 'new-arrivals',
                  },
                  'productReferences': <Map<String, Object?>>[
                    <String, Object?>{
                      'id': 'gid://shopify/Product/1',
                      'variantId': 'gid://shopify/ProductVariant/1',
                    },
                  ],
                  'collectionReferences': <Map<String, Object?>>[
                    <String, Object?>{'handle': 'new-arrivals'},
                  ],
                  'analytics': <String, Object?>{'campaign': 'phase-5'},
                  'accessibility': <String, Object?>{
                    'semanticLabel': 'FLEXWOLF hero banner',
                    'imageAltText': 'Athlete wearing FLEXWOLF',
                    'ctaLabel': 'Shop new arrivals',
                  },
                  'presentation': <String, Object?>{'layout': 'full_bleed'},
                  'fallback': <String, Object?>{'hideWhenEmpty': true},
                },
              ),
            ],
          ),
        );

        expect(result.isValid, isTrue);
        final config = result.config!;
        expect(config.sections.map((section) => section.id), <String>[
          'hero',
          'late',
        ]);
        final hero = config.sections.first;
        expect(hero.analyticsName, 'main_hero_banner');
        expect(hero.content.body, 'Native configurable content.');
        expect(hero.content.media?.mobileUrl, contains('home-mobile'));
        expect(hero.destination?.type, HomeDestinationType.collection);
        expect(
          hero.productReferences.single.variantId,
          'gid://shopify/ProductVariant/1',
        );
        expect(hero.collectionReferences.single.handle, 'new-arrivals');
        expect(hero.accessibility.ctaLabel, 'Shop new arrivals');
      },
    );

    test(
      'unknown section type is skipped without invalidating valid sections',
      () {
        final result = HomeConfigParser.parse(
          _validConfig(
            sections: <Map<String, Object?>>[
              _section('hero', 'main_hero_banner'),
              _section('future', 'future_ai_rail', order: 2),
            ],
          ),
        );

        expect(result.isValid, isTrue);
        expect(result.config!.sections.single.id, 'hero');
        expect(result.unknownSections.single.remoteType, 'future_ai_rail');
        expect(
          result.diagnostics.single,
          contains('Unknown Home section type'),
        );
      },
    );

    test('missing required section field skips only that section', () {
      final result = HomeConfigParser.parse(
        _validConfig(
          sections: <Map<String, Object?>>[
            _section('hero', 'main_hero_banner'),
            <String, Object?>{
              'sectionType': 'new_arrivals',
              'displayOrder': 2,
              'title': 'Missing id',
            },
          ],
        ),
      );

      expect(result.isValid, isTrue);
      expect(result.config!.sections.single.id, 'hero');
      expect(
        result.diagnostics,
        contains('Home section is missing sectionId.'),
      );
    });

    test('disabled section remains represented but not active', () {
      final config = HomeConfig.fromJson(
        _validConfig(
          sections: <Map<String, Object?>>[
            _section(
              'disabled',
              'sale',
              extra: <String, Object?>{'enabled': false},
            ),
          ],
        ),
      );

      expect(config.sections.single.enabled, isFalse);
      expect(config.activeSections(DateTime.utc(2026, 9)), isEmpty);
    });

    test('duplicate section IDs reject the full remote config', () {
      final result = HomeConfigParser.parse(
        _validConfig(
          sections: <Map<String, Object?>>[
            _section('hero', 'main_hero_banner'),
            _section('hero', 'new_drop', order: 2),
          ],
        ),
      );

      expect(result.isValid, isFalse);
      expect(result.diagnostics.single, contains('Duplicate Home section id'));
    });

    test('malformed section does not destroy other valid sections', () {
      final result = HomeConfigParser.parse(
        _validConfig(
          sections: <Map<String, Object?>>[
            _section('hero', 'main_hero_banner'),
            _section(
              'bad',
              'countdown',
              order: 2,
              extra: <String, Object?>{'title': ''},
            ),
          ],
        ),
      );

      expect(result.isValid, isTrue);
      expect(result.config!.sections.single.id, 'hero');
      expect(result.diagnostics.single, contains('no usable content'));
    });

    test(
      'schema version is required and unsupported versions are rejected',
      () {
        expect(
          HomeConfigParser.parse(<String, Object?>{'sections': const []})
              .isValid,
          isFalse,
        );
        expect(
          HomeConfigParser.parse(<String, Object?>{
            'schemaVersion': 99,
            'sections': const [],
          }).diagnostics.single,
          contains('Unsupported Home schema version'),
        );
      },
    );

    test(
      'scheduling evaluates before, active, and after windows using UTC',
      () {
        final config = HomeConfig.fromJson(
          _validConfig(
            sections: <Map<String, Object?>>[
              _section(
                'drop',
                'limited_drop',
                extra: <String, Object?>{
                  'startsAt': '2026-09-01T10:00:00+05:30',
                  'endsAt': '2026-09-01T12:00:00+05:30',
                },
              ),
            ],
          ),
        );

        expect(config.activeSections(DateTime.utc(2026, 9, 1, 4, 0)), isEmpty);
        expect(
          config.activeSections(DateTime.utc(2026, 9, 1, 5, 0)),
          hasLength(1),
        );
        expect(config.activeSections(DateTime.utc(2026, 9, 1, 6, 30)), isEmpty);
      },
    );

    test('invalid date range and malformed dates skip the section', () {
      final reversed = HomeConfigParser.parse(
        _validConfig(
          sections: <Map<String, Object?>>[
            _section(
              'timer',
              'countdown',
              extra: <String, Object?>{
                'startsAt': '2026-09-02T00:00:00Z',
                'endsAt': '2026-09-01T00:00:00Z',
              },
            ),
          ],
        ),
      );
      final malformed = HomeConfigParser.parse(
        _validConfig(
          sections: <Map<String, Object?>>[
            _section(
              'timer',
              'countdown',
              extra: <String, Object?>{'startsAt': 'soon'},
            ),
          ],
        ),
      );

      expect(reversed.config!.sections, isEmpty);
      expect(reversed.diagnostics.single, contains('endsAt before startsAt'));
      expect(malformed.config!.sections, isEmpty);
      expect(
        malformed.diagnostics.single,
        contains('malformed schedule dates'),
      );
    });

    test('destination/action parser supports approved destination types', () {
      for (final type in <String>[
        'product',
        'collection',
        'internal_route',
        'search',
        'promotion',
        'drop',
        'external_url',
      ]) {
        final destination = HomeDestination.tryParse(<String, Object?>{
          'type': type,
          'value': 'target',
        });
        expect(destination, isNotNull, reason: type);
      }
      expect(
        HomeDestination.tryParse(<String, Object?>{'type': 'none'}),
        isNotNull,
      );
      expect(
        HomeDestination.tryParse(<String, Object?>{'type': 'product'}),
        isNull,
      );
    });

    test('product and collection references parse id and handle forms', () {
      expect(
        ShopifyProductReference.listFromJson(<Object?>[
          'gid://shopify/Product/1',
          <String, Object?>{'handle': 'flex-tee'},
        ]),
        hasLength(2),
      );
      expect(
        ShopifyCollectionReference.listFromJson(<Object?>[
          'gid://shopify/Collection/1',
          <String, Object?>{'handle': 'shorts'},
        ]),
        hasLength(2),
      );
    });
  });

  group('Home content repository cache fallback', () {
    test(
      'valid remote config is returned and cached as last known good',
      () async {
        final storage = InMemoryLocalStorage();
        final repository = DefaultHomeContentRepository(
          remoteDataSource: FakeRemoteHomeContentDataSource(_validConfig()),
          cachedDataSource: LocalCachedHomeContentDataSource(storage: storage),
          clock: const FixedClock('2026-09-01T00:00:00Z'),
        );

        final result = await repository.fetchHomeContent();
        final cached = await LocalCachedHomeContentDataSource(storage: storage)
            .readLastKnownGoodConfig();

        expect(result.source, HomeContentSource.remote);
        expect(result.config!.cache.cachedAt, DateTime.utc(2026, 9));
        expect(cached, isNotNull);
      },
    );

    test('remote failure falls back to valid cached config', () async {
      final storage = InMemoryLocalStorage();
      final cache = LocalCachedHomeContentDataSource(storage: storage);
      await cache.writeLastKnownGoodConfig(
        HomeConfig.fromJson(_validConfig()).withCacheMetadata(
          HomeConfigCacheMetadata(
            version: 'schema-1',
            cachedAt: DateTime.utc(2026, 8, 31),
          ),
        ),
      );
      final repository = DefaultHomeContentRepository(
        remoteDataSource: const FailingRemoteHomeContentDataSource(),
        cachedDataSource: cache,
        clock: const FixedClock('2026-09-01T00:00:00Z'),
      );

      final result = await repository.fetchHomeContent();

      expect(result.source, HomeContentSource.cache);
      expect(result.isStale, isTrue);
      expect(result.config!.sections.single.id, 'hero');
    });

    test('malformed remote config falls back to valid cached config', () async {
      final storage = InMemoryLocalStorage();
      final cache = LocalCachedHomeContentDataSource(storage: storage);
      await cache.writeLastKnownGoodConfig(
        HomeConfig.fromJson(_validConfig()).withCacheMetadata(
          HomeConfigCacheMetadata(
            version: 'schema-1',
            cachedAt: DateTime.utc(2026, 8, 31),
          ),
        ),
      );
      final repository = DefaultHomeContentRepository(
        remoteDataSource: FakeRemoteHomeContentDataSource(<String, Object?>{
          'schemaVersion': 99,
          'sections': const [],
        }),
        cachedDataSource: cache,
        clock: const FixedClock('2026-09-01T00:00:00Z'),
      );

      final result = await repository.fetchHomeContent();

      expect(result.source, HomeContentSource.cache);
      expect(result.warning, contains('invalid'));
    });

    test('no remote and no cache returns safe unavailable result', () async {
      final repository = DefaultHomeContentRepository(
        remoteDataSource: const FailingRemoteHomeContentDataSource(),
        cachedDataSource: LocalCachedHomeContentDataSource(
          storage: InMemoryLocalStorage(),
        ),
        clock: const FixedClock('2026-09-01T00:00:00Z'),
      );

      final result = await repository.fetchHomeContent();

      expect(result.source, HomeContentSource.unavailable);
      expect(result.config, isNull);
      expect(result.warning, isNot(contains('Exception')));
    });
  });
}

Map<String, Object?> _validConfig({List<Map<String, Object?>>? sections}) {
  return <String, Object?>{
    'schemaVersion': HomeSectionRegistry.currentSchemaVersion,
    'generatedAt': '2026-09-01T00:00:00Z',
    'sections':
        sections ??
        <Map<String, Object?>>[_section('hero', 'main_hero_banner')],
  };
}

Map<String, Object?> _section(
  String id,
  String type, {
  int order = 1,
  Map<String, Object?> extra = const <String, Object?>{},
}) {
  return <String, Object?>{
    'sectionId': id,
    'sectionType': type,
    'enabled': true,
    'displayOrder': order,
    'title': 'FLEXWOLF',
    ...extra,
  };
}

class FakeRemoteHomeContentDataSource implements RemoteHomeContentDataSource {
  const FakeRemoteHomeContentDataSource(this.value);

  final Map<String, Object?> value;

  @override
  Future<Map<String, Object?>> fetchHomeConfig() async => value;
}

class FailingRemoteHomeContentDataSource
    implements RemoteHomeContentDataSource {
  const FailingRemoteHomeContentDataSource();

  @override
  Future<Map<String, Object?>> fetchHomeConfig() async {
    throw StateError('offline');
  }
}

class FixedClock implements Clock {
  const FixedClock(this.value);

  final String value;

  @override
  DateTime nowUtc() => DateTime.parse(value).toUtc();
}
