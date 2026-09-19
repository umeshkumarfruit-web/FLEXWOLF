import 'package:flexwolf/features/shop/domain/collection.dart';
import 'package:flexwolf/features/shop/domain/pagination.dart';
import 'package:flexwolf/features/shop/domain/product.dart';

abstract interface class ProductRepository {
  Future<PaginatedResult<ProductSummary>> fetchProducts(
    PaginationRequest pagination,
  );

  Future<ProductSummary?> fetchProductByHandle(String handle);

  Future<ProductSummary?> fetchProductById(String id);

  Future<PaginatedResult<ProductSummary>> fetchProductsByCollection({
    required String collectionHandle,
    required PaginationRequest pagination,
  });
}

abstract interface class CollectionRepository {
  Future<PaginatedResult<ProductCollection>> fetchCollections(
    PaginationRequest pagination,
  );

  Future<ProductCollection?> fetchCollectionByHandle({
    required String handle,
    PaginationRequest? productsPagination,
  });
}
