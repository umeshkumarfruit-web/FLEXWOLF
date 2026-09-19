import 'package:flexwolf/app/router/route_names.dart';
import 'package:flexwolf/app/theme/app_theme.dart';
import 'package:flexwolf/features/home/home.dart';
import 'package:flexwolf/features/shop/domain/collection.dart';
import 'package:flexwolf/features/shop/domain/money.dart';
import 'package:flexwolf/features/shop/domain/product.dart';
import 'package:flexwolf/features/shop/domain/product_media.dart';
import 'package:flexwolf/features/shop/domain/product_variant.dart';
import 'package:flexwolf/core/services/service_registry.dart';
import 'package:flexwolf/integrations/analytics/analytics_boundary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  test('renderer registry maps every contract section type', () {
    expect(
      HomeSectionRendererRegistry.registeredTypes.toSet(),
      HomeSectionType.values.toSet(),
    );
    for (final type in HomeSectionType.values) {
      expect(
        HomeSectionRendererRegistry.hasRenderer(type),
        isTrue,
        reason: type.name,
      );
    }
  });

  testWidgets('Dynamic Home renders ordered enabled active sections only', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        config: _config(<Map<String, Object?>>[
          _section(
            'late',
            'countdown',
            order: 30,
            extra: _activeCountdown('Late'),
          ),
          _section(
            'disabled',
            'main_hero_banner',
            order: 1,
            extra: <String, Object?>{'enabled': false},
          ),
          _section(
            'future',
            'countdown',
            order: 2,
            extra: <String, Object?>{
              ..._activeCountdown('Future'),
              'startsAt': '2030-01-01T00:00:00Z',
              'endsAt': '2030-01-02T00:00:00Z',
            },
          ),
          _section('hero', 'main_hero_banner', order: 10),
          _section(
            'rail',
            'new_drop',
            order: 20,
            extra: <String, Object?>{
              'productReferences': <Map<String, Object?>>[
                <String, Object?>{'handle': 'flex-tee'},
              ],
            },
          ),
        ]),
        resolver: FakeHomeCommerceResolver(
          products: <String, ProductSummary>{
            'flex-tee': _product('flex-tee', 'Flex Tee'),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hero'), findsOneWidget);
    expect(find.text('Disabled'), findsNothing);
    expect(find.text('Future'), findsNothing);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -520));
    await tester.pumpAndSettle();

    expect(find.text('Flex Tee'), findsOneWidget);
  });

  testWidgets('hero renders configured image text and CTA', (tester) async {
    await tester.pumpWidget(
      _testApp(
        config: _config(<Map<String, Object?>>[
          _section('hero', 'main_hero_banner'),
        ]),
      ),
    );
    await tester.pump();

    expect(find.text('Hero'), findsOneWidget);
    expect(find.text('Shop now'), findsOneWidget);
    expect(find.text('HERO SUBTITLE'), findsOneWidget);
  });

  testWidgets('product rail shows loading skeleton then Shopify products', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        config: _config(<Map<String, Object?>>[
          _section(
            'rail',
            'new_drop',
            extra: <String, Object?>{
              'productReferences': <Map<String, Object?>>[
                <String, Object?>{'handle': 'flex-tee'},
              ],
            },
          ),
        ]),
        resolver: DelayedHomeCommerceResolver(_product('flex-tee', 'Flex Tee')),
      ),
    );

    expect(find.text('Loading products'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Flex Tee'), findsOneWidget);
    expect(find.text('USD 48.00'), findsOneWidget);
  });

  testWidgets('product rail collapses completely when it has no products', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        config: _config(<Map<String, Object?>>[
          _section(
            'rail',
            'new_drop',
            extra: <String, Object?>{
              'fallback': <String, Object?>{'hideWhenEmpty': false},
            },
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(
      find.byKey(
        const ValueKey<String>('home-section-empty-rail'),
        skipOffstage: false,
      ),
      findsNothing,
    );
    expect(find.text('CLIENT DEPENDENCY'), findsNothing);
  });

  testWidgets('product rail API failure shows section-level error', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        config: _config(<Map<String, Object?>>[
          _section(
            'rail',
            'new_drop',
            extra: <String, Object?>{
              'productReferences': <Map<String, Object?>>[
                <String, Object?>{'handle': 'broken'},
              ],
            },
          ),
        ]),
        resolver: const ThrowingHomeCommerceResolver(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Products could not load'), findsOneWidget);
  });

  testWidgets(
    'collection navigation and product navigation use existing route boundary',
    (tester) async {
      final router = _router();
      await tester.pumpWidget(
        _testApp(
          router: router,
          config: _config(<Map<String, Object?>>[
            _section(
              'rail',
              'new_drop',
              extra: <String, Object?>{
                'productReferences': <Map<String, Object?>>[
                  <String, Object?>{'handle': 'flex-tee'},
                ],
              },
            ),
          ]),
          resolver: FakeHomeCommerceResolver(
            products: <String, ProductSummary>{
              'flex-tee': _product('flex-tee', 'Flex Tee'),
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Flex Tee'));
      await tester.pumpAndSettle();
      expect(
        router.routeInformationProvider.value.uri.path,
        '/shop/products/flex-tee',
      );
    },
  );

  test('invalid destination is ignored safely by dispatcher', () {
    const dispatcher = HomeActionDispatcher();
    expect(dispatcher.canDispatch(null), isFalse);
    expect(
      dispatcher.canDispatch(
        const HomeDestination(type: HomeDestinationType.none),
      ),
      isFalse,
    );
  });

  testWidgets('countdown hides expired campaign and renders active campaign', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        config: _config(<Map<String, Object?>>[
          _section(
            'expired',
            'countdown',
            order: 1,
            extra: <String, Object?>{
              'title': 'Expired',
              'startsAt': '2026-08-31T00:00:00Z',
              'endsAt': '2026-08-31T01:00:00Z',
            },
          ),
          _section(
            'active',
            'countdown',
            order: 2,
            extra: _activeCountdown('Active Countdown'),
          ),
        ]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Expired'), findsNothing);
    expect(find.text('Active Countdown'), findsOneWidget);
    expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
  });

  testWidgets('cached Home fallback displays stale banner', (tester) async {
    await tester.pumpWidget(
      _testApp(
        result: HomeContentResult(
          config: HomeConfig.fromJson(
            _config(<Map<String, Object?>>[
              _section('hero', 'main_hero_banner'),
            ]),
          ),
          source: HomeContentSource.cache,
          warning: 'cached',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Showing saved Home content.'), findsOneWidget);
    expect(find.text('Hero'), findsOneWidget);
  });

  testWidgets('malformed optional sections do not break valid Home rendering', (
    tester,
  ) async {
    final parsed = HomeConfigParser.parse(
      _config(<Map<String, Object?>>[
        _section('hero', 'main_hero_banner'),
        <String, Object?>{
          'sectionId': 'bad',
          'sectionType': 'new_drop',
          'enabled': true,
          'displayOrder': 2,
          'productReferences': <Object?>[<String, Object?>{}],
        },
      ]),
    );

    await tester.pumpWidget(
      _testApp(
        result: HomeContentResult(
          config: parsed.config,
          source: HomeContentSource.remote,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hero'), findsOneWidget);
    expect(find.text('bad'), findsNothing);
  });
}

Widget _testApp({
  Map<String, Object?>? config,
  HomeContentResult? result,
  HomeCommerceResolver resolver = const FakeHomeCommerceResolver(),
  GoRouter? router,
}) {
  final effectiveRouter = router ?? _router();
  return ProviderScope(
    overrides: [
      homeContentRepositoryProvider.overrideWithValue(
        FakeHomeContentRepository(
          result ??
              HomeContentResult(
                config: HomeConfig.fromJson(config!),
                source: HomeContentSource.remote,
              ),
        ),
      ),
      homeCommerceResolverProvider.overrideWithValue(resolver),
      homeClockProvider.overrideWithValue(const FixedClock()),
      analyticsGatewayProvider.overrideWithValue(FakeAnalyticsGateway()),
    ],
    child: MaterialApp.router(
      theme: AppTheme.light(),
      routerConfig: effectiveRouter,
    ),
  );
}

GoRouter _router() {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.home,
        builder: (_, _) => const Scaffold(body: DynamicHomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.shop,
        builder: (_, _) => const Scaffold(body: Text('Shop route')),
        routes: [
          GoRoute(
            path: 'products/:handle',
            name: AppRouteNames.product,
            builder: (_, state) => Scaffold(
              body: Text('Product ${state.pathParameters['handle']}'),
            ),
          ),
          GoRoute(
            path: 'collections/:handle',
            name: AppRouteNames.collection,
            builder: (_, state) => Scaffold(
              body: Text('Collection ${state.pathParameters['handle']}'),
            ),
          ),
          GoRoute(
            path: 'promotions/:id',
            name: AppRouteNames.promotion,
            builder: (_, state) =>
                Scaffold(body: Text('Promotion ${state.pathParameters['id']}')),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (_, _) => const Scaffold(body: Text('Search route')),
      ),
    ],
  );
}

Map<String, Object?> _config(List<Map<String, Object?>> sections) {
  return <String, Object?>{'schemaVersion': 1, 'sections': sections};
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
    'title': id == 'hero' ? 'Hero' : id,
    'subtitle': id == 'hero' ? 'Hero subtitle' : null,
    'ctaText': id == 'hero' ? 'Shop now' : 'View all',
    'media': <String, Object?>{
      'url': 'https://cdn.flexwolf.co/test.jpg',
      'altText': 'Hero image',
      'aspectRatio': 1.0,
    },
    'destination': <String, Object?>{
      'type': 'collection',
      'value': 'new-arrivals',
    },
    ...extra,
  };
}

Map<String, Object?> _activeCountdown(String title) {
  return <String, Object?>{
    'title': title,
    'startsAt': '2026-09-01T00:00:00Z',
    'endsAt': '2030-09-01T00:00:00Z',
  };
}

ProductSummary _product(String handle, String title) {
  return ProductSummary(
    id: 'gid://shopify/Product/$handle',
    handle: handle,
    title: title,
    availableForSale: true,
    featuredImage: const ProductImage(
      url: 'https://cdn.flexwolf.co/product.jpg',
      altText: 'Product image',
    ),
    variants: <ProductVariant>[
      ProductVariant(
        id: 'gid://shopify/ProductVariant/$handle',
        availableForSale: true,
        price: Money(amount: DecimalAmount.parse('48.00'), currencyCode: 'USD'),
        compareAtPrice: Money(
          amount: DecimalAmount.parse('64.00'),
          currencyCode: 'USD',
        ),
      ),
    ],
  );
}

class FakeHomeContentRepository implements HomeContentRepository {
  const FakeHomeContentRepository(this.result);

  final HomeContentResult result;

  @override
  Future<HomeContentResult> fetchHomeContent() async => result;
}

class FakeHomeCommerceResolver implements HomeCommerceResolver {
  const FakeHomeCommerceResolver({
    this.products = const <String, ProductSummary>{},
    this.collections = const <String, ProductCollection>{},
  });

  final Map<String, ProductSummary> products;
  final Map<String, ProductCollection> collections;

  @override
  Future<ProductCollection?> resolveCollection(
    ShopifyCollectionReference reference,
  ) async {
    return collections[reference.handle ?? reference.id];
  }

  @override
  Future<ProductSummary?> resolveProduct(
    ShopifyProductReference reference,
  ) async {
    return products[reference.handle ?? reference.id];
  }
}

class DelayedHomeCommerceResolver implements HomeCommerceResolver {
  const DelayedHomeCommerceResolver(this.product);

  final ProductSummary product;

  @override
  Future<ProductCollection?> resolveCollection(
    ShopifyCollectionReference reference,
  ) async => null;

  @override
  Future<ProductSummary?> resolveProduct(
    ShopifyProductReference reference,
  ) async {
    await Future<void>.delayed(const Duration(milliseconds: 1));
    return product;
  }
}

class ThrowingHomeCommerceResolver implements HomeCommerceResolver {
  const ThrowingHomeCommerceResolver();

  @override
  Future<ProductCollection?> resolveCollection(
    ShopifyCollectionReference reference,
  ) async {
    throw StateError('shopify failed');
  }

  @override
  Future<ProductSummary?> resolveProduct(
    ShopifyProductReference reference,
  ) async {
    throw StateError('shopify failed');
  }
}

class FixedClock implements Clock {
  const FixedClock();

  @override
  DateTime nowUtc() => DateTime.utc(2026, 9, 1, 12);
}

class FakeAnalyticsGateway implements AnalyticsGateway {
  final events = <AnalyticsEvent>[];

  @override
  Future<void> track(AnalyticsEvent event) async {
    events.add(event);
  }
}
