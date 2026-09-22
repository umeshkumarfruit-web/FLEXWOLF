import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/services/service_registry.dart';
import 'package:flexwolf/features/home/data/default_home_content_repository.dart';
import 'package:flexwolf/features/home/data/development_home_content_data_source.dart';
import 'package:flexwolf/features/home/data/home_content_data_sources.dart';
import 'package:flexwolf/features/home/domain/home_config.dart';
import 'package:flexwolf/features/home/domain/home_content_repository.dart';
import 'package:flexwolf/features/shop/data/shop_providers.dart';
import 'package:flexwolf/features/shop/domain/collection.dart';
import 'package:flexwolf/features/shop/domain/product.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final homeClockProvider = Provider<Clock>((ref) => const SystemClock());

final remoteHomeContentDataSourceProvider =
    Provider<RemoteHomeContentDataSource>((ref) {
      // Use the storefront layout in every build until a live CMS source is wired.
      return const DevelopmentHomeContentDataSource();
    });

final cachedHomeContentDataSourceProvider =
    Provider<CachedHomeContentDataSource>(
      (ref) => LocalCachedHomeContentDataSource(
        storage: ref.watch(localStorageProvider),
      ),
    );

final homeCommerceResolverProvider = Provider<HomeCommerceResolver>(
  (ref) => CachingHomeCommerceResolver(
    ShopifyHomeCommerceResolver(
      productRepository: ref.watch(productRepositoryProvider),
      collectionRepository: ref.watch(collectionRepositoryProvider),
    ),
  ),
);

final homeContentRepositoryProvider = Provider<HomeContentRepository>((ref) {
  return DefaultHomeContentRepository(
    remoteDataSource: ref.watch(remoteHomeContentDataSourceProvider),
    cachedDataSource: ref.watch(cachedHomeContentDataSourceProvider),
    clock: ref.watch(homeClockProvider),
    logger: ref.watch(loggerProvider),
  );
});

final homeContentResultProvider = FutureProvider.autoDispose<HomeContentResult>(
  (ref) {
    return ref.watch(homeContentRepositoryProvider).fetchHomeContent();
  },
);

class ClientDependencyRemoteHomeContentDataSource
    implements RemoteHomeContentDataSource {
  const ClientDependencyRemoteHomeContentDataSource();

  @override
  Future<Map<String, Object?>> fetchHomeConfig() {
    throw const AppException(
      kind: AppErrorKind.network,
      message: 'CLIENT DEPENDENCY: Home CMS/Remote Config provider is not configured.',
      code: 'home_content_provider_not_configured',
      isRetryable: true,
    );
  }
}

class ClientDependencyHomeCommerceResolver implements HomeCommerceResolver {
  const ClientDependencyHomeCommerceResolver();

  @override
  Future<ProductCollection?> resolveCollection(
    ShopifyCollectionReference reference,
  ) async {
    return null;
  }

  @override
  Future<ProductSummary?> resolveProduct(
    ShopifyProductReference reference,
  ) async {
    return null;
  }
}
