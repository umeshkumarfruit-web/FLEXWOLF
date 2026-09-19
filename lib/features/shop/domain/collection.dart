import 'package:flexwolf/features/shop/domain/pagination.dart';
import 'package:flexwolf/features/shop/domain/product.dart';
import 'package:flexwolf/features/shop/domain/product_media.dart';

class ProductCollection {
  const ProductCollection({
    required this.id,
    required this.handle,
    required this.title,
    this.description,
    this.image,
    this.products,
  });

  factory ProductCollection.fromShopify(Map<String, Object?> json) {
    final id = json['id'];
    final handle = json['handle'];
    final title = json['title'];
    if (id is! String || handle is! String || title is! String) {
      throw const FormatException('Invalid Shopify collection payload.');
    }

    return ProductCollection(
      id: id,
      handle: handle,
      title: title,
      description: json['description'] as String?,
      image: json['image'] is Map<String, Object?>
          ? ProductImage.fromShopify(json['image']! as Map<String, Object?>)
          : null,
      products: json['products'] is Map<String, Object?>
          ? PaginatedResult<ProductSummary>(
              items: _connectionNodes(json['products'])
                  .map(ProductSummary.fromShopify)
                  .toList(growable: false),
              pageInfo: PageInfo.fromShopify(
                (json['products']! as Map<String, Object?>)['pageInfo']
                    as Map<String, Object?>,
              ),
            )
          : null,
    );
  }

  final String id;
  final String handle;
  final String title;
  final String? description;
  final ProductImage? image;
  final PaginatedResult<ProductSummary>? products;
}

List<Map<String, Object?>> _connectionNodes(Object? value) {
  if (value is! Map<String, Object?>) {
    return const <Map<String, Object?>>[];
  }
  final nodes = value['nodes'];
  if (nodes is List) {
    return nodes.whereType<Map<String, Object?>>().toList(growable: false);
  }
  return const <Map<String, Object?>>[];
}
