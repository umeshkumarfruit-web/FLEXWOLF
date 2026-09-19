class ProductBadgeRule {
  const ProductBadgeRule({
    required this.label,
    required this.possibleSources,
    required this.status,
  });

  final String label;
  final List<String> possibleSources;
  final BadgeRuleStatus status;
}

enum BadgeRuleStatus { planned, needsShopifyEvidence }

const futureBadgeRules = <ProductBadgeRule>[
  ProductBadgeRule(
    label: 'NEW',
    possibleSources: [
      'Shopify data',
      'metafield',
      'tag',
      'CMS rule',
      'derived app rule',
    ],
    status: BadgeRuleStatus.needsShopifyEvidence,
  ),
  ProductBadgeRule(
    label: 'SALE',
    possibleSources: ['compare-at price', 'discount', 'tag', 'CMS rule'],
    status: BadgeRuleStatus.needsShopifyEvidence,
  ),
  ProductBadgeRule(
    label: 'BEST SELLER',
    possibleSources: ['Shopify data', 'metafield', 'metaobject', 'CMS rule'],
    status: BadgeRuleStatus.needsShopifyEvidence,
  ),
  ProductBadgeRule(
    label: 'APP EXCLUSIVE',
    possibleSources: ['metafield', 'metaobject', 'tag', 'CMS rule'],
    status: BadgeRuleStatus.needsShopifyEvidence,
  ),
  ProductBadgeRule(
    label: 'LOW STOCK',
    possibleSources: ['inventory rule', 'metafield', 'derived app rule'],
    status: BadgeRuleStatus.needsShopifyEvidence,
  ),
  ProductBadgeRule(
    label: 'RESTOCKED',
    possibleSources: ['inventory rule', 'metafield', 'CMS rule'],
    status: BadgeRuleStatus.needsShopifyEvidence,
  ),
];
