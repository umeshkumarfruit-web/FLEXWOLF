import 'package:flexwolf/features/home/data/development_home_content_data_source.dart';
import 'package:flexwolf/features/home/domain/home_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('storefront home has the live campaign section order', () async {
    final json = await const DevelopmentHomeContentDataSource()
        .fetchHomeConfig();
    final parsed = HomeConfigParser.parse(json);

    expect(parsed.isValid, isTrue);
    expect(parsed.config?.sections.map((section) => section.id), [
      'storefront-hero',
      'flex-arm-feature',
      'prime-strength',
      'just-in',
      'bottomwear-carousel',
      'performance-banner',
      'everyday-performance',
    ]);
  });
}
