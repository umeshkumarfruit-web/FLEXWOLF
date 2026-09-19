import 'package:flutter/foundation.dart';

@immutable
class HomeSectionDefinition {
  const HomeSectionDefinition({
    required this.type,
    required this.remoteValue,
    required this.analyticsName,
    required this.requiresShopifyProducts,
    required this.requiresShopifyCollections,
    required this.requiresPersonalization,
    required this.requiresMediaProvider,
  });

  final HomeSectionType type;
  final String remoteValue;
  final String analyticsName;
  final bool requiresShopifyProducts;
  final bool requiresShopifyCollections;
  final bool requiresPersonalization;
  final bool requiresMediaProvider;
}

@immutable
class UnknownHomeSection {
  const UnknownHomeSection({
    required this.id,
    required this.remoteType,
    required this.displayOrder,
  });

  final String id;
  final String remoteType;
  final int? displayOrder;
}

enum HomeSectionType {
  mainHeroBanner,
  newDrop,
  newArrivals,
  bestSellers,
  trending,
  sale,
  collection365,
  flexArmCollection,
  shorts,
  sweats,
  appExclusives,
  recommendedForYou,
  recentlyViewed,
  completeTheLook,
  creatorPicks,
  athletePicks,
  shoppableVideos,
  customerUgc,
  backInStock,
  limitedDrop,
  countdown,
  memberExclusive,
}

abstract final class HomeSectionRegistry {
  static const currentSchemaVersion = 1;
  static const supportedSchemaVersions = <int>{1};

  static const definitions = <HomeSectionDefinition>[
    HomeSectionDefinition(
      type: HomeSectionType.mainHeroBanner,
      remoteValue: 'main_hero_banner',
      analyticsName: 'main_hero_banner',
      requiresShopifyProducts: false,
      requiresShopifyCollections: false,
      requiresPersonalization: false,
      requiresMediaProvider: false,
    ),
    HomeSectionDefinition(
      type: HomeSectionType.newDrop,
      remoteValue: 'new_drop',
      analyticsName: 'new_drop',
      requiresShopifyProducts: true,
      requiresShopifyCollections: true,
      requiresPersonalization: false,
      requiresMediaProvider: false,
    ),
    HomeSectionDefinition(
      type: HomeSectionType.newArrivals,
      remoteValue: 'new_arrivals',
      analyticsName: 'new_arrivals',
      requiresShopifyProducts: true,
      requiresShopifyCollections: true,
      requiresPersonalization: false,
      requiresMediaProvider: false,
    ),
    HomeSectionDefinition(
      type: HomeSectionType.bestSellers,
      remoteValue: 'best_sellers',
      analyticsName: 'best_sellers',
      requiresShopifyProducts: true,
      requiresShopifyCollections: true,
      requiresPersonalization: false,
      requiresMediaProvider: false,
    ),
    HomeSectionDefinition(
      type: HomeSectionType.trending,
      remoteValue: 'trending',
      analyticsName: 'trending',
      requiresShopifyProducts: true,
      requiresShopifyCollections: true,
      requiresPersonalization: false,
      requiresMediaProvider: false,
    ),
    HomeSectionDefinition(
      type: HomeSectionType.sale,
      remoteValue: 'sale',
      analyticsName: 'sale',
      requiresShopifyProducts: true,
      requiresShopifyCollections: true,
      requiresPersonalization: false,
      requiresMediaProvider: false,
    ),
    HomeSectionDefinition(
      type: HomeSectionType.collection365,
      remoteValue: '365_collection',
      analyticsName: '365_collection',
      requiresShopifyProducts: true,
      requiresShopifyCollections: true,
      requiresPersonalization: false,
      requiresMediaProvider: false,
    ),
    HomeSectionDefinition(
      type: HomeSectionType.flexArmCollection,
      remoteValue: 'flex_arm_collection',
      analyticsName: 'flex_arm_collection',
      requiresShopifyProducts: true,
      requiresShopifyCollections: true,
      requiresPersonalization: false,
      requiresMediaProvider: false,
    ),
    HomeSectionDefinition(
      type: HomeSectionType.shorts,
      remoteValue: 'shorts',
      analyticsName: 'shorts',
      requiresShopifyProducts: true,
      requiresShopifyCollections: true,
      requiresPersonalization: false,
      requiresMediaProvider: false,
    ),
    HomeSectionDefinition(
      type: HomeSectionType.sweats,
      remoteValue: 'sweats',
      analyticsName: 'sweats',
      requiresShopifyProducts: true,
      requiresShopifyCollections: true,
      requiresPersonalization: false,
      requiresMediaProvider: false,
    ),
    HomeSectionDefinition(
      type: HomeSectionType.appExclusives,
      remoteValue: 'app_exclusives',
      analyticsName: 'app_exclusives',
      requiresShopifyProducts: true,
      requiresShopifyCollections: true,
      requiresPersonalization: false,
      requiresMediaProvider: false,
    ),
    HomeSectionDefinition(
      type: HomeSectionType.recommendedForYou,
      remoteValue: 'recommended_for_you',
      analyticsName: 'recommended_for_you',
      requiresShopifyProducts: true,
      requiresShopifyCollections: false,
      requiresPersonalization: true,
      requiresMediaProvider: false,
    ),
    HomeSectionDefinition(
      type: HomeSectionType.recentlyViewed,
      remoteValue: 'recently_viewed',
      analyticsName: 'recently_viewed',
      requiresShopifyProducts: true,
      requiresShopifyCollections: false,
      requiresPersonalization: true,
      requiresMediaProvider: false,
    ),
    HomeSectionDefinition(
      type: HomeSectionType.completeTheLook,
      remoteValue: 'complete_the_look',
      analyticsName: 'complete_the_look',
      requiresShopifyProducts: true,
      requiresShopifyCollections: false,
      requiresPersonalization: false,
      requiresMediaProvider: false,
    ),
    HomeSectionDefinition(
      type: HomeSectionType.creatorPicks,
      remoteValue: 'creator_picks',
      analyticsName: 'creator_picks',
      requiresShopifyProducts: true,
      requiresShopifyCollections: false,
      requiresPersonalization: false,
      requiresMediaProvider: true,
    ),
    HomeSectionDefinition(
      type: HomeSectionType.athletePicks,
      remoteValue: 'athlete_picks',
      analyticsName: 'athlete_picks',
      requiresShopifyProducts: true,
      requiresShopifyCollections: false,
      requiresPersonalization: false,
      requiresMediaProvider: true,
    ),
    HomeSectionDefinition(
      type: HomeSectionType.shoppableVideos,
      remoteValue: 'shoppable_videos',
      analyticsName: 'shoppable_videos',
      requiresShopifyProducts: true,
      requiresShopifyCollections: false,
      requiresPersonalization: false,
      requiresMediaProvider: true,
    ),
    HomeSectionDefinition(
      type: HomeSectionType.customerUgc,
      remoteValue: 'customer_ugc',
      analyticsName: 'customer_ugc',
      requiresShopifyProducts: true,
      requiresShopifyCollections: false,
      requiresPersonalization: false,
      requiresMediaProvider: true,
    ),
    HomeSectionDefinition(
      type: HomeSectionType.backInStock,
      remoteValue: 'back_in_stock',
      analyticsName: 'back_in_stock',
      requiresShopifyProducts: true,
      requiresShopifyCollections: false,
      requiresPersonalization: false,
      requiresMediaProvider: false,
    ),
    HomeSectionDefinition(
      type: HomeSectionType.limitedDrop,
      remoteValue: 'limited_drop',
      analyticsName: 'limited_drop',
      requiresShopifyProducts: true,
      requiresShopifyCollections: true,
      requiresPersonalization: false,
      requiresMediaProvider: false,
    ),
    HomeSectionDefinition(
      type: HomeSectionType.countdown,
      remoteValue: 'countdown',
      analyticsName: 'countdown',
      requiresShopifyProducts: false,
      requiresShopifyCollections: false,
      requiresPersonalization: false,
      requiresMediaProvider: false,
    ),
    HomeSectionDefinition(
      type: HomeSectionType.memberExclusive,
      remoteValue: 'member_exclusive',
      analyticsName: 'member_exclusive',
      requiresShopifyProducts: true,
      requiresShopifyCollections: true,
      requiresPersonalization: false,
      requiresMediaProvider: false,
    ),
  ];

  static final Map<String, HomeSectionDefinition> _byRemoteValue = {
    for (final definition in definitions) definition.remoteValue: definition,
  };

  static HomeSectionDefinition? definitionForRemoteValue(String value) {
    return _byRemoteValue[value.trim().toLowerCase()];
  }

  static HomeSectionDefinition definitionForType(HomeSectionType type) {
    return definitions.firstWhere((definition) => definition.type == type);
  }

  static String analyticsNameFor(HomeSectionType type) {
    return definitionForType(type).analyticsName;
  }

  static bool supportsSchemaVersion(int version) {
    return supportedSchemaVersions.contains(version);
  }
}
