class BundleReadinessRule {
  const BundleReadinessRule({required this.name, required this.status});

  final String name;
  final String status;
}

const futureBundleRules = <BundleReadinessRule>[
  BundleReadinessRule(name: '1 Pack', status: 'PLANNED'),
  BundleReadinessRule(name: '3 Pack', status: 'PLANNED'),
  BundleReadinessRule(name: '5 Pack', status: 'PLANNED'),
  BundleReadinessRule(name: '6 Pack', status: 'PLANNED'),
  BundleReadinessRule(name: 'Different colors/sizes', status: 'PLANNED'),
  BundleReadinessRule(name: 'Quantity bundles', status: 'PLANNED'),
  BundleReadinessRule(name: 'Mix-and-match', status: 'PLANNED'),
  BundleReadinessRule(name: 'Automatic discounts', status: 'PLANNED'),
  BundleReadinessRule(name: 'Shopify bundles', status: 'PLANNED'),
  BundleReadinessRule(name: 'Promotional bundles', status: 'PLANNED'),
];
