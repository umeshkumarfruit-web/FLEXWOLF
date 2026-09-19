import 'package:flexwolf/features/home/domain/home_content_repository.dart';
import 'package:flexwolf/features/home/domain/home_section_registry.dart';

class DevelopmentHomeContentDataSource implements RemoteHomeContentDataSource {
  const DevelopmentHomeContentDataSource();

  @override
  Future<Map<String, Object?>> fetchHomeConfig() async {
    return <String, Object?>{
      'schemaVersion': HomeSectionRegistry.currentSchemaVersion,
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'sections': <Map<String, Object?>>[
        _hero(),
        _rail(
          'new-drop',
          'new_drop',
          20,
          'New Drop',
          'Configured Shopify products from the latest launch.',
        ),
        _collection(
          'new-arrivals',
          'new_arrivals',
          30,
          'New Arrivals',
          'Fresh product configured by FLEXWOLF.',
          'new-arrivals',
        ),
        _collection(
          'best-sellers',
          'best_sellers',
          40,
          'Best Sellers',
          'Top-performing Shopify collection rail.',
          'best-seller',
        ),
        _collection(
          'trending',
          'trending',
          50,
          'Trending',
          'Current demand signals when the provider is connected.',
          'all-products',
        ),
        _collection(
          'sale',
          'sale',
          60,
          'Sale',
          'Discounted products remain priced by Shopify.',
          'summer-sale',
        ),
        _collection(
          'collection-365',
          '365_collection',
          70,
          '365 Collection',
          'Everyday training staples.',
          '365-collection',
        ),
        _collection(
          'flex-arm',
          'flex_arm_collection',
          80,
          'Flex Arm Collection',
          'Arm-day essentials configured by collection.',
          'flex-arm',
        ),
        _collection(
          'shorts',
          'shorts',
          90,
          'Shorts',
          'Training shorts from Shopify.',
          'shorts',
        ),
        _collection(
          'sweats',
          'sweats',
          100,
          'Sweats',
          'Layering and recovery staples.',
          'sweats',
        ),
        _rail(
          'app-exclusives',
          'app_exclusives',
          110,
          'App Exclusives',
          'Renderer-ready; offer enforcement is server-side later.',
        ),
        _rail(
          'recommended',
          'recommended_for_you',
          120,
          'Recommended For You',
          'Personalization provider pending.',
        ),
        _rail(
          'recently-viewed',
          'recently_viewed',
          130,
          'Recently Viewed',
          'History provider pending.',
        ),
        _rail(
          'complete-look',
          'complete_the_look',
          140,
          'Complete The Look',
          'Configured complementary Shopify products.',
        ),
        _editorial(
          'creator-picks',
          'creator_picks',
          150,
          'Creator Picks',
          'Approved creator merchandising content pending.',
        ),
        _editorial(
          'athlete-picks',
          'athlete_picks',
          160,
          'Athlete Picks',
          'Approved athlete merchandising content pending.',
        ),
        _media(
          'shoppable-videos',
          'shoppable_videos',
          170,
          'Shoppable Videos',
          'Approved video provider/content pending.',
        ),
        _media(
          'customer-ugc',
          'customer_ugc',
          180,
          'Customer UGC',
          'Approved moderated customer content pending.',
        ),
        _rail(
          'back-in-stock',
          'back_in_stock',
          190,
          'Back In Stock',
          'Subscription/notification integration pending.',
        ),
        _collection(
          'limited-drop',
          'limited_drop',
          200,
          'Limited Drop',
          'Scheduled launch presentation; purchase rules later.',
          'new-arrivals',
        ),
        _countdown(),
        _rail(
          'member-exclusive',
          'member_exclusive',
          220,
          'Member Exclusive',
          'Membership remains a later contract phase.',
        ),
      ],
    };
  }

  Map<String, Object?> _hero() {
    return <String, Object?>{
      'sectionId': 'dev-hero',
      'sectionType': 'main_hero_banner',
      'enabled': true,
      'displayOrder': 10,
      'title': 'FLEXWOLF',
      'subtitle': 'Performance apparel',
      'body': 'Built for the work. Styled for everywhere after.',
      'ctaText': 'Shop the sale',
      'media': <String, Object?>{
        'url': 'https://flexwolf.co/cdn/shop/files/NEW_WBSITE_DESK_d761921c-0419-4878-9725-c4b59dbd2ecf.png?v=1785260855&width=1600',
        'mobileUrl': 'https://flexwolf.co/cdn/shop/files/NEW_WBSITE_mob_135a208a-f656-4e25-aa16-0f44f0ab31a5.png?v=1785260856&width=1000',
        'altText': 'FLEXWOLF performance apparel campaign',
        'aspectRatio': 0.75,
      },
      'destination': <String, Object?>{
        'type': 'collection',
        'value': 'new-arrivals',
      },
      'analytics': <String, Object?>{
        'campaign': 'development_dynamic_home_preview',
      },
      'accessibility': <String, Object?>{
        'semanticLabel': 'FLEXWOLF performance apparel campaign',
        'imageAltText': 'FLEXWOLF performance apparel campaign',
        'ctaLabel': 'Shop the FLEXWOLF sale',
      },
    };
  }

  Map<String, Object?> _rail(
    String id,
    String type,
    int order,
    String title,
    String subtitle,
  ) {
    return <String, Object?>{
      'sectionId': id,
      'sectionType': type,
      'enabled': true,
      'displayOrder': order,
      'title': title,
      'subtitle': subtitle,
      'productReferences': <Map<String, Object?>>[
        <String, Object?>{'handle': 'flex-arm-tank'},
        <String, Object?>{'handle': 'apex-performance-shorts'},
        <String, Object?>{'handle': 'wolfmark-core-oversized-tee'},
      ],
      'destination': <String, Object?>{
        'type': 'collection',
        'value': 'all-products',
      },
      'fallback': <String, Object?>{'hideWhenEmpty': false},
    };
  }

  Map<String, Object?> _collection(
    String id,
    String type,
    int order,
    String title,
    String subtitle,
    String handle,
  ) {
    final mediaUrl = switch (handle) {
      '365-collection' => 'https://flexwolf.co/cdn/shop/files/5_SHORTS-3153.jpg?v=1781652128&width=1000',
      'flex-arm' => 'https://flexwolf.co/cdn/shop/files/KevinxOSTAnkandtee-2697.jpg?v=1781652116&width=1000',
      'shorts' => 'https://flexwolf.co/cdn/shop/files/5_SHORTS-3171.jpg?v=1781652128&width=1000',
      'sweats' => 'https://flexwolf.co/cdn/shop/files/Yellow_Hoodie_-_18_-_674833_42d794b9-2f25-4e53-8e0c-08e0a4fa64d8.jpg?v=1781652106&width=1000',
      _ => null,
    };
    return <String, Object?>{
      'sectionId': id,
      'sectionType': type,
      'enabled': true,
      'displayOrder': order,
      'title': title,
      'subtitle': subtitle,
      'collectionReferences': <Map<String, Object?>>[
        <String, Object?>{'handle': handle},
      ],
      'productReferences': <Map<String, Object?>>[
        <String, Object?>{'handle': 'flex-arm-tank'},
        <String, Object?>{'handle': 'apex-performance-shorts'},
        <String, Object?>{'handle': 'wolfmark-core-oversized-tee'},
      ],
      if (mediaUrl != null)
        'media': <String, Object?>{
          'url': mediaUrl,
          'mobileUrl': mediaUrl,
          'altText': '$title FLEXWOLF collection',
          'aspectRatio': 0.75,
        },
      'destination': <String, Object?>{'type': 'collection', 'value': handle},
      'fallback': <String, Object?>{'hideWhenEmpty': true},
    };
  }

  Map<String, Object?> _editorial(
    String id,
    String type,
    int order,
    String title,
    String subtitle,
  ) {
    return <String, Object?>{
      'sectionId': id,
      'sectionType': type,
      'enabled': true,
      'displayOrder': order,
      'title': title,
      'subtitle': subtitle,
      'body': 'Renderer-ready editorial section. Use only approved identities, endorsements, and assets.',
      'productReferences': <Map<String, Object?>>[
        <String, Object?>{'handle': 'flex-arm-tank'},
      ],
      'fallback': <String, Object?>{'hideWhenEmpty': false},
    };
  }

  Map<String, Object?> _media(
    String id,
    String type,
    int order,
    String title,
    String subtitle,
  ) {
    return <String, Object?>{
      'sectionId': id,
      'sectionType': type,
      'enabled': true,
      'displayOrder': order,
      'title': title,
      'subtitle': subtitle,
      'body': 'No autoplay. Media provider is intentionally not wired until approved.',
      'fallback': <String, Object?>{'hideWhenEmpty': false},
    };
  }

  Map<String, Object?> _countdown() {
    return <String, Object?>{
      'sectionId': 'countdown',
      'sectionType': 'countdown',
      'enabled': true,
      'displayOrder': 210,
      'title': 'Countdown',
      'subtitle': 'Schedule-driven renderer preview',
      'startsAt': DateTime.now()
          .toUtc()
          .subtract(const Duration(hours: 1))
          .toIso8601String(),
      'endsAt': DateTime.now()
          .toUtc()
          .add(const Duration(days: 2))
          .toIso8601String(),
      'ctaText': 'View Drop',
      'destination': <String, Object?>{
        'type': 'promotion',
        'value': 'development-drop',
      },
    };
  }
}
