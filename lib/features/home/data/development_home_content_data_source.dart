import 'package:flexwolf/features/home/domain/home_content_repository.dart';
import 'package:flexwolf/features/home/domain/home_section_registry.dart';

/// Storefront sections and public campaign assets mirrored from flexwolf.co.
class DevelopmentHomeContentDataSource implements RemoteHomeContentDataSource {
  const DevelopmentHomeContentDataSource();

  @override
  Future<Map<String, Object?>> fetchHomeConfig() async => <String, Object?>{
    'schemaVersion': HomeSectionRegistry.currentSchemaVersion,
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
    'sections': <Map<String, Object?>>[
      <String, Object?>{
        'sectionId': 'storefront-hero',
        'sectionType': 'main_hero_banner',
        'enabled': true,
        'displayOrder': 10,
        'media': <String, Object?>{
          'url': 'https://flexwolf.co/cdn/shop/files/NEW_WBSITE_DESK_d761921c-0419-4878-9725-c4b59dbd2ecf.png?v=1785260855&width=1600',
          'mobileUrl': 'https://flexwolf.co/cdn/shop/files/NEW_WBSITE_mob_135a208a-f656-4e25-aa16-0f44f0ab31a5.png?v=1785260856&width=1000',
          'altText': 'FLEXWOLF summer sale campaign',
          'aspectRatio': 0.75,
        },
        'destination': <String, Object?>{
          'type': 'collection',
          'value': 'summer-sale',
        },
      },
      <String, Object?>{
        'sectionId': 'flex-arm-feature',
        'sectionType': 'flex_arm_collection',
        'enabled': true,
        'displayOrder': 20,
        'title': 'Flex Arm Tank',
        'productReferences': <Map<String, Object?>>[
          <String, Object?>{'handle': 'flex-arm-tank'},
        ],
        'destination': <String, Object?>{
          'type': 'product',
          'value': 'flex-arm-tank',
        },
      },
      _products(
        'prime-strength',
        'new_arrivals',
        30,
        'Prime Strength',
        const <String>[
          'boxy-heavyweight-tee',
          '365-crew-tee',
          'flexwolf-alphaskin-full-sleeve-tee',
          'flexwolf-core-oversized-tee',
          'wolfmark-wrap-oversized-tee',
          'wolfmark-core-oversized-tee',
          'air-mesh-long-sleeve',
        ],
      ),
      _products('just-in', 'new_drop', 40, 'JUST IN', const <String>[
        'mens-performance-stringer',
        'cloud-flex-joggers',
        'airflow-performance-tank',
        'boxy-heavyweight-tee',
        '365-crew-tee',
        'apex-training-shorts',
        'wolfmark-throne-muscle-tee',
      ]),
      <String, Object?>{
        'sectionId': 'bottomwear-carousel',
        'sectionType': 'shorts',
        'enabled': true,
        'displayOrder': 50,
        'title': 'Bottomwear',
        'destination': <String, Object?>{
          'type': 'collection',
          'value': 'shorts',
        },
      },
      <String, Object?>{
        'sectionId': 'performance-banner',
        'sectionType': 'sweats',
        'enabled': true,
        'displayOrder': 60,
        'title': 'LOOK BETTER. TRAIN HARDER.',
        'subtitle':
            'Premium athletic apparel engineered for comfort and performance.',
        'ctaText': 'SHOP BEST SELLERS',
        'media': <String, Object?>{
          'url': 'https://flexwolf.co/cdn/shop/files/new_banner_21.065.2026.png?v=1781989121&width=1600',
          'mobileUrl': 'https://flexwolf.co/cdn/shop/files/new_banner_21.065.2026.png?v=1781989121&width=900',
          'altText': 'FLEXWOLF performance campaign',
          'aspectRatio': 1.4,
        },
        'destination': <String, Object?>{
          'type': 'collection',
          'value': 'best-seller',
        },
      },
      _products(
        'everyday-performance',
        'best_sellers',
        70,
        'Everyday Performance',
        const <String>[
          'apex-2-in-1-shorts-5',
          'apex-training-shorts',
          'flexwolf-alphaskin-compression-tees',
          'apex-7-bubblecrush-shorts',
          'flexwolf-core-muscle-tee',
          'mens-performance-stringer',
        ],
      ),
    ],
  };

  Map<String, Object?> _products(
    String id,
    String type,
    int order,
    String title,
    List<String> handles,
  ) => <String, Object?>{
    'sectionId': id,
    'sectionType': type,
    'enabled': true,
    'displayOrder': order,
    'title': title,
    'productReferences': <Map<String, Object?>>[
      for (final handle in handles) <String, Object?>{'handle': handle},
    ],
    'destination': <String, Object?>{
      'type': 'collection',
      'value': id == 'just-in'
          ? 'new-arrivals'
          : id == 'everyday-performance'
          ? 'best-seller'
          : 'all-products',
    },
    'ctaText': 'VIEW ALL',
  };
}
