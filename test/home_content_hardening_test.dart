import 'package:flexwolf/core/storage/local_storage.dart';
import 'package:flexwolf/features/home/data/home_content_data_sources.dart';
import 'package:flexwolf/features/home/domain/home_config.dart';
import 'package:flexwolf/features/home/domain/home_content_repository.dart';
import 'package:flexwolf/features/home/domain/home_section_registry.dart';
import 'package:flexwolf/features/shop/domain/collection.dart';
import 'package:flexwolf/features/shop/domain/product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('rejects a config made entirely of malformed sections', () {
    final result = HomeConfigParser.parse(<String, Object?>{
      'schemaVersion': HomeSectionRegistry.currentSchemaVersion,
      'sections': <Object?>[
        <String, Object?>{
          'sectionId': 'broken',
          'sectionType': 'new_drop',
          'displayOrder': -1,
          'enabled': 'yes',
        },
      ],
    });

    expect(result.config, isNotNull);
    expect(result.config!.sections, isEmpty);
    expect(result.diagnostics, contains(contains('invalid displayOrder')));
  });

  test('rejects duplicate IDs even when the duplicate section is invalid', () {
    final result = HomeConfigParser.parse(<String, Object?>{
      'schemaVersion': 1,
      'sections': <Object?>[
        <String, Object?>{
          'sectionId': 'same',
          'sectionType': 'main_hero_banner',
          'displayOrder': 1,
          'title': 'Hero',
        },
        <String, Object?>{
          'sectionId': 'same',
          'sectionType': 'unknown_future_type',
          'displayOrder': 2,
        },
      ],
    });

    expect(result.config, isNull);
    expect(result.diagnostics.single, contains('Duplicate Home section id'));
  });

  test('rejects cached config with a mismatched cache version', () async {
    final storage = InMemoryLocalStorage();
    await storage.writeString(
      'home.last_known_good_config.v1',
      '{"schemaVersion":1,"cache":{"version":"schema-99","cachedAt":"2026-09-01T00:00:00Z"},"sections":[]}',
    );

    final cached = await LocalCachedHomeContentDataSource(storage: storage)
        .readLastKnownGoodConfig();

    expect(cached, isNull);
  });

  test('coalesces identical Shopify references', () async {
    final delegate = CountingResolver();
    final resolver = CachingHomeCommerceResolver(delegate);
    const reference = ShopifyProductReference(handle: 'flex-tee');

    final results = await Future.wait(<Future<ProductSummary?>>[
      resolver.resolveProduct(reference),
      resolver.resolveProduct(reference),
    ]);

    expect(results, hasLength(2));
    expect(delegate.productCalls, 1);
  });
}

class CountingResolver implements HomeCommerceResolver {
  int productCalls = 0;

  @override
  Future<ProductSummary?> resolveProduct(
    ShopifyProductReference reference,
  ) async {
    productCalls += 1;
    return null;
  }

  @override
  Future<ProductCollection?> resolveCollection(
    ShopifyCollectionReference reference,
  ) async {
    return null;
  }
}
