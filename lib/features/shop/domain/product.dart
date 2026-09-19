import 'package:flexwolf/features/shop/domain/metafield.dart';
import 'package:flexwolf/features/shop/domain/product_media.dart';
import 'package:flexwolf/features/shop/domain/product_variant.dart';

class ProductSummary {
  const ProductSummary({
    required this.id,
    required this.handle,
    required this.title,
    required this.availableForSale,
    this.description,
    this.descriptionHtml,
    this.productType,
    this.vendor,
    this.featuredImage,
    this.images = const <ProductImage>[],
    this.media = const <ProductMedia>[],
    this.variants = const <ProductVariant>[],
    this.options = const <ProductOption>[],
    this.tags = const <String>[],
    this.metafields = const <ShopifyMetafield>[],
    this.collectionIds = const <String>[],
    this.updatedAt,
  });

  factory ProductSummary.fromShopify(Map<String, Object?> json) {
    final id = json['id'];
    final handle = json['handle'];
    final title = json['title'];
    final availableForSale = json['availableForSale'];
    if (id is! String ||
        handle is! String ||
        title is! String ||
        availableForSale is! bool) {
      throw const FormatException('Invalid Shopify product payload.');
    }

    return ProductSummary(
      id: id,
      handle: handle,
      title: title,
      availableForSale: availableForSale,
      description: json['description'] as String?,
      descriptionHtml: json['descriptionHtml'] as String?,
      productType: json['productType'] as String?,
      vendor: json['vendor'] as String?,
      featuredImage: json['featuredImage'] is Map<String, Object?>
          ? ProductImage.fromShopify(
              json['featuredImage']! as Map<String, Object?>,
            )
          : null,
      images: _connectionNodes(json['images'])
          .map(ProductImage.fromShopify)
          .toList(growable: false),
      media: _connectionNodes(json['media'])
          .map(ProductMedia.fromShopify)
          .toList(growable: false),
      variants: _connectionNodes(json['variants'])
          .map(ProductVariant.fromShopify)
          .toList(growable: false),
      options: _listMaps(json['options'])
          .map(ProductOption.fromShopify)
          .toList(growable: false),
      tags: _stringList(json['tags']),
      metafields: _listMaps(json['metafields'])
          .map(ShopifyMetafield.fromShopify)
          .toList(growable: false),
      collectionIds: _connectionNodes(json['collections'])
          .map((node) => node['id'])
          .whereType<String>()
          .toList(growable: false),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
    );
  }

  final String id;
  final String handle;
  final String title;
  final String? description;
  final String? descriptionHtml;
  final String? productType;
  final String? vendor;
  final List<String> tags;
  final ProductImage? featuredImage;
  final List<ProductImage> images;
  final List<ProductMedia> media;
  final List<ProductVariant> variants;
  final List<ProductOption> options;
  final bool availableForSale;
  final List<ShopifyMetafield> metafields;
  final List<String> collectionIds;
  final DateTime? updatedAt;
}

List<Map<String, Object?>> _connectionNodes(Object? value) {
  if (value is! Map<String, Object?>) {
    return const <Map<String, Object?>>[];
  }
  final nodes = value['nodes'];
  if (nodes is List) {
    return nodes.whereType<Map<String, Object?>>().toList(growable: false);
  }
  final edges = value['edges'];
  if (edges is List) {
    return edges
        .whereType<Map<String, Object?>>()
        .map((edge) => edge['node'])
        .whereType<Map<String, Object?>>()
        .toList(growable: false);
  }
  return const <Map<String, Object?>>[];
}

List<Map<String, Object?>> _listMaps(Object? value) {
  if (value is! List) {
    return const <Map<String, Object?>>[];
  }
  return value.whereType<Map<String, Object?>>().toList(growable: false);
}

List<String> _stringList(Object? value) {
  if (value is! List) {
    return const <String>[];
  }
  return value.whereType<String>().toList(growable: false);
}
