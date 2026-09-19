// ignore_for_file: prefer_initializing_formals

import 'package:flexwolf/features/home/domain/home_config.dart';
import 'package:flexwolf/features/shop/domain/collection.dart';
import 'package:flexwolf/features/shop/domain/product.dart';
import 'package:flexwolf/features/shop/domain/shop_repositories.dart';

abstract interface class HomeContentRepository {
  Future<HomeContentResult> fetchHomeContent();
}

abstract interface class RemoteHomeContentDataSource {
  Future<Map<String, Object?>> fetchHomeConfig();
}

abstract interface class CachedHomeContentDataSource {
  Future<CachedHomeConfig?> readLastKnownGoodConfig();

  Future<void> writeLastKnownGoodConfig(HomeConfig config);
}

abstract interface class HomeCommerceResolver {
  Future<ProductSummary?> resolveProduct(ShopifyProductReference reference);

  Future<ProductCollection?> resolveCollection(
    ShopifyCollectionReference reference,
  );
}

class ShopifyHomeCommerceResolver implements HomeCommerceResolver {
  const ShopifyHomeCommerceResolver({
    required ProductRepository productRepository,
    required CollectionRepository collectionRepository,
  }) : _productRepository = productRepository,
       _collectionRepository = collectionRepository;

  final ProductRepository _productRepository;
  final CollectionRepository _collectionRepository;

  @override
  Future<ProductSummary?> resolveProduct(ShopifyProductReference reference) {
    final id = reference.id;
    if (id != null) {
      return _productRepository.fetchProductById(id);
    }
    final handle = reference.handle;
    if (handle != null) {
      return _productRepository.fetchProductByHandle(handle);
    }
    return Future<ProductSummary?>.value();
  }

  @override
  Future<ProductCollection?> resolveCollection(
    ShopifyCollectionReference reference,
  ) {
    final handle = reference.handle;
    if (handle != null) {
      return _collectionRepository.fetchCollectionByHandle(handle: handle);
    }
    return Future<ProductCollection?>.value();
  }
}

/// Coalesces identical Home requests while sections are resolving.
class CachingHomeCommerceResolver implements HomeCommerceResolver {
  CachingHomeCommerceResolver(this._delegate);

  final HomeCommerceResolver _delegate;
  final Map<String, Future<ProductSummary?>> _products = {};
  final Map<String, Future<ProductCollection?>> _collections = {};

  @override
  Future<ProductSummary?> resolveProduct(ShopifyProductReference reference) {
    final key = 'product:${reference.id ?? reference.handle ?? ''}';
    return _products[key] ??= _delegate.resolveProduct(reference);
  }

  @override
  Future<ProductCollection?> resolveCollection(
    ShopifyCollectionReference reference,
  ) {
    final key = 'collection:${reference.id ?? reference.handle ?? ''}';
    return _collections[key] ??= _delegate.resolveCollection(reference);
  }
}

class CachedHomeConfig {
  const CachedHomeConfig({required this.config, required this.cachedAt});

  final HomeConfig config;
  final DateTime cachedAt;
}

class HomeContentResult {
  const HomeContentResult({
    required this.config,
    required this.source,
    this.warning,
    this.diagnostics = const <String>[],
  });

  final HomeConfig? config;
  final HomeContentSource source;
  final String? warning;
  final List<String> diagnostics;

  bool get hasConfig => config != null;
  bool get isStale => source == HomeContentSource.cache;
}

enum HomeContentSource { remote, cache, unavailable }
