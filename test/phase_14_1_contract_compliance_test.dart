import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Phase 14.1 audit records every required contract item once', () {
    final audit = File(
      'docs/PHASE_14_1_CONTRACT_COMPLIANCE_AUDIT.md',
    ).readAsStringSync();

    const requiredItems = <String>[
      'App Platform',
      'Custom Design',
      'Navigation',
      'Homepage',
      'Shopify Connection',
      'Shop',
      'Collections',
      'Filters',
      'Sorting',
      'Search',
      'Product Page',
      'Color Variants',
      'Size Chart',
      'Bundles',
      'Cart',
      'Cart Sync',
      'Checkout',
      'Customer Account',
      'Order History',
      'Tracking',
      'Returns',
      'Wishlist',
    ];
    const allowedStatuses = <String>{
      'COMPLETE',
      'PARTIAL',
      'CLIENT DEPENDENCY',
      'MISSING',
    };

    for (final item in requiredItems) {
      final matches = RegExp(
        r'^\| ' + RegExp.escape(item) + r' \| ([A-Z ]+) \|',
        multiLine: true,
      ).allMatches(audit).toList();
      expect(matches, hasLength(1), reason: item);
      expect(allowedStatuses, contains(matches.single.group(1)), reason: item);
    }
  });
}
