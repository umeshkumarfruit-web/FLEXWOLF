import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/features/shop/data/queries/storefront_queries.dart';
import 'package:flexwolf/features/shop/domain/collection.dart';
import 'package:flexwolf/features/shop/domain/pagination.dart';
import 'package:flexwolf/features/shop/domain/product.dart';
import 'package:flexwolf/features/shop/domain/shop_repositories.dart';
import 'package:flexwolf/integrations/shopify/graphql/shopify_graphql_client.dart';

class ShopifyProductRepository implements ProductRepository {
  const ShopifyProductRepository(this._client);

  final ShopifyGraphqlClient _client;

  @override
  Future<PaginatedResult<ProductSummary>> fetchProducts(
    PaginationRequest pagination,
  ) async {
    final response = await _client.query(
      ShopifyGraphqlRequest(
        document: StorefrontQueries.products,
        operationName: 'Products',
        variables: _paginationVariables(pagination),
      ),
    );
    final data = _dataMap(response);
    return _parseProductConnection(data['products']);
  }

  @override
  Future<ProductSummary?> fetchProductByHandle(String handle) async {
    final response = await _client.query(
      ShopifyGraphqlRequest(
        document: StorefrontQueries.productByHandle,
        operationName: 'ProductByHandle',
        variables: <String, Object?>{'handle': handle},
      ),
    );
    final product = _dataMap(response)['product'];
    return product is Map<String, Object?>
        ? ProductSummary.fromShopify(product)
        : null;
  }

  @override
  Future<ProductSummary?> fetchProductById(String id) async {
    final response = await _client.query(
      ShopifyGraphqlRequest(
        document: StorefrontQueries.productById,
        operationName: 'ProductById',
        variables: <String, Object?>{'id': id},
      ),
    );
    final product = _dataMap(response)['product'];
    return product is Map<String, Object?>
        ? ProductSummary.fromShopify(product)
        : null;
  }

  @override
  Future<PaginatedResult<ProductSummary>> fetchProductsByCollection({
    required String collectionHandle,
    required PaginationRequest pagination,
  }) async {
    final response = await _client.query(
      ShopifyGraphqlRequest(
        document: StorefrontQueries.collectionByHandle,
        operationName: 'CollectionByHandle',
        variables: <String, Object?>{
          'handle': collectionHandle,
          ..._paginationVariables(pagination),
        },
      ),
    );
    final collection = _dataMap(response)['collection'];
    if (collection is! Map<String, Object?>) {
      throw const AppException(
        kind: AppErrorKind.unavailable,
        message: 'Collection was not found.',
        code: 'collection_not_found',
      );
    }
    return _parseProductConnection(collection['products']);
  }
}

class ShopifyCollectionRepository implements CollectionRepository {
  const ShopifyCollectionRepository(this._client);

  final ShopifyGraphqlClient _client;

  @override
  Future<PaginatedResult<ProductCollection>> fetchCollections(
    PaginationRequest pagination,
  ) async {
    final response = await _client.query(
      ShopifyGraphqlRequest(
        document: StorefrontQueries.collections,
        operationName: 'Collections',
        variables: _paginationVariables(pagination),
      ),
    );
    final data = _dataMap(response);
    return _parseCollectionConnection(data['collections']);
  }

  @override
  Future<ProductCollection?> fetchCollectionByHandle({
    required String handle,
    PaginationRequest? productsPagination,
  }) async {
    final pagination = productsPagination ?? const PaginationRequest();
    final response = await _client.query(
      ShopifyGraphqlRequest(
        document: StorefrontQueries.collectionByHandle,
        operationName: 'CollectionByHandle',
        variables: <String, Object?>{
          'handle': handle,
          ..._paginationVariables(pagination),
        },
      ),
    );
    final collection = _dataMap(response)['collection'];
    return collection is Map<String, Object?>
        ? ProductCollection.fromShopify(collection)
        : null;
  }
}

Map<String, Object?> _dataMap(ShopifyGraphqlResponse response) {
  final data = response.data;
  if (data is Map<String, Object?>) {
    return data;
  }
  throw const AppException(
    kind: AppErrorKind.api,
    message: 'Shopify response is missing data.',
    code: 'shopify_missing_data',
  );
}

PaginatedResult<ProductSummary> _parseProductConnection(Object? connection) {
  final map = _connectionMap(connection);
  return PaginatedResult<ProductSummary>(
    items: _nodes(map).map(ProductSummary.fromShopify).toList(growable: false),
    pageInfo: PageInfo.fromShopify(map['pageInfo'] as Map<String, Object?>),
  );
}

PaginatedResult<ProductCollection> _parseCollectionConnection(
  Object? connection,
) {
  final map = _connectionMap(connection);
  return PaginatedResult<ProductCollection>(
    items: _nodes(map)
        .map(ProductCollection.fromShopify)
        .toList(growable: false),
    pageInfo: PageInfo.fromShopify(map['pageInfo'] as Map<String, Object?>),
  );
}

Map<String, Object?> _connectionMap(Object? connection) {
  if (connection is Map<String, Object?> &&
      connection['pageInfo'] is Map<String, Object?>) {
    return connection;
  }
  throw const AppException(
    kind: AppErrorKind.api,
    message: 'Malformed Shopify pagination response.',
    code: 'shopify_malformed_pagination',
  );
}

List<Map<String, Object?>> _nodes(Map<String, Object?> connection) {
  final nodes = connection['nodes'];
  if (nodes is List) {
    return nodes.whereType<Map<String, Object?>>().toList(growable: false);
  }
  return const <Map<String, Object?>>[];
}

Map<String, Object?> _paginationVariables(PaginationRequest pagination) {
  return <String, Object?>{
    'first': pagination.first,
    if (pagination.after != null) 'after': pagination.after,
  };
}
