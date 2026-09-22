import 'dart:convert';

import 'package:flexwolf/features/shop/domain/collection.dart';
import 'package:flexwolf/features/shop/domain/money.dart';
import 'package:flexwolf/features/shop/domain/pagination.dart';
import 'package:flexwolf/features/shop/domain/product.dart';
import 'package:flexwolf/features/shop/domain/product_media.dart';
import 'package:flexwolf/features/shop/domain/product_variant.dart';
import 'package:flexwolf/features/shop/domain/shop_repositories.dart';
import 'package:flutter/services.dart';

/// Read-only catalog from the public FLEXWOLF Shopify storefront.
class PublicStorefrontCatalogRepository
    implements ProductRepository, CollectionRepository {
  PublicStorefrontCatalogRepository({NetworkAssetBundle? bundle})
    : _bundle = bundle ?? NetworkAssetBundle(Uri.parse('https://flexwolf.co/'));

  final NetworkAssetBundle _bundle;

  @override
  Future<PaginatedResult<ProductSummary>> fetchProducts(
    PaginationRequest pagination,
  ) => fetchProductsByCollection(
    collectionHandle: 'all-products',
    pagination: pagination,
  );

  @override
  Future<PaginatedResult<ProductSummary>> fetchProductsByCollection({
    required String collectionHandle,
    required PaginationRequest pagination,
  }) async {
    final page = int.tryParse(pagination.after ?? '') ?? 1;
    final limit = pagination.first.clamp(1, 250);
    final json = await _get(
      'collections/${Uri.encodeComponent(collectionHandle)}/products.json?limit=$limit&page=$page',
    );
    final items = (json['products'] as List? ?? const [])
        .whereType<Map<String, Object?>>()
        .map(_product)
        .toList(growable: false);
    return PaginatedResult(
      items: items,
      pageInfo: PageInfo(
        hasNextPage: items.length == limit,
        endCursor: items.length == limit ? '${page + 1}' : null,
      ),
    );
  }

  @override
  Future<ProductSummary?> fetchProductByHandle(String handle) async {
    final json = await _get('products/${Uri.encodeComponent(handle)}.json');
    final value = json['product'];
    if (value is! Map<String, Object?>) return null;
    Map<String, bool> availability = const {};
    try {
      final ajax = await _get('products/${Uri.encodeComponent(handle)}.js');
      availability = {
        for (final variant
            in (ajax['variants'] as List? ?? const [])
                .whereType<Map<String, Object?>>())
          if (variant['id'] != null)
            variant['id'].toString(): variant['available'] == true,
      };
    } catch (_) {
      // The product page can still display if availability lookup fails.
    }
    return _product(value, availability: availability);
  }

  @override
  Future<ProductSummary?> fetchProductById(String id) async {
    final products = await fetchProducts(const PaginationRequest(first: 250));
    for (final product in products.items) {
      if (product.id == id) return product;
    }
    return null;
  }

  @override
  Future<PaginatedResult<ProductCollection>> fetchCollections(
    PaginationRequest pagination,
  ) async {
    final page = int.tryParse(pagination.after ?? '') ?? 1;
    final limit = pagination.first.clamp(1, 250);
    final json = await _get('collections.json?limit=$limit&page=$page');
    final items = (json['collections'] as List? ?? const [])
        .whereType<Map<String, Object?>>()
        .map(
          (value) => ProductCollection(
            id: 'gid://shopify/Collection/${value['id']}',
            handle: value['handle'] as String? ?? '',
            title: value['title'] as String? ?? '',
            description: value['body_html'] as String?,
            image: _image(value['image']),
          ),
        )
        .where((collection) => collection.handle.isNotEmpty)
        .toList(growable: false);
    return PaginatedResult(
      items: items,
      pageInfo: PageInfo(
        hasNextPage: items.length == limit,
        endCursor: items.length == limit ? '${page + 1}' : null,
      ),
    );
  }

  @override
  Future<ProductCollection?> fetchCollectionByHandle({
    required String handle,
    PaginationRequest? productsPagination,
  }) async {
    final products = await fetchProductsByCollection(
      collectionHandle: handle,
      pagination: productsPagination ?? const PaginationRequest(),
    );
    return ProductCollection(
      id: 'gid://shopify/Collection/$handle',
      handle: handle,
      title: handle.replaceAll('-', ' ').toUpperCase(),
      products: products,
    );
  }

  Future<Map<String, Object?>> _get(String path) async {
    final raw = await _bundle.loadString(path);
    final parsed = jsonDecode(raw);
    if (parsed is! Map<String, Object?>) {
      throw const FormatException('Invalid public Shopify catalog JSON.');
    }
    return parsed;
  }

  ProductSummary _product(
    Map<String, Object?> json, {
    Map<String, bool> availability = const {},
  }) {
    final rawVariants = (json['variants'] as List? ?? const [])
        .whereType<Map<String, Object?>>()
        .toList(growable: false);
    final options = (json['options'] as List? ?? const [])
        .whereType<Map<String, Object?>>()
        .toList(growable: false);
    final rawImages = (json['images'] as List? ?? const [])
        .whereType<Map<String, Object?>>()
        .toList(growable: false);
    final imageByVariantId = <String, ProductImage>{};
    for (final rawImage in rawImages) {
      final image = _image(rawImage);
      if (image == null) continue;
      for (final id in rawImage['variant_ids'] as List? ?? const []) {
        imageByVariantId[id.toString()] = image;
      }
    }
    final variants = rawVariants
        .map((value) {
          Money? compareAt;
          final compare = value['compare_at_price']?.toString();
          if (compare != null && compare.isNotEmpty) {
            compareAt = Money(
              amount: DecimalAmount.parse(compare),
              currencyCode: 'USD',
            );
          }
          return ProductVariant(
            id: 'gid://shopify/ProductVariant/${value['id']}',
            title: value['title'] as String?,
            availableForSale:
                availability[value['id'].toString()] ??
                (value['available'] == true),
            price: Money(
              amount: DecimalAmount.parse(value['price'].toString()),
              currencyCode: 'USD',
            ),
            compareAtPrice: compareAt,
            image:
                _image(value['featured_image']) ??
                imageByVariantId[value['id'].toString()],
            selectedOptions: [
              for (var i = 0; i < options.length; i++)
                if (value['option${i + 1}'] is String)
                  SelectedOption(
                    name: options[i]['name'] as String? ?? 'Option ${i + 1}',
                    value: value['option${i + 1}']! as String,
                  ),
            ],
          );
        })
        .toList(growable: false);
    final images = rawImages
        .map(_image)
        .whereType<ProductImage>()
        .toList(growable: false);
    return ProductSummary(
      id: 'gid://shopify/Product/${json['id']}',
      handle: json['handle'] as String? ?? '',
      title: json['title'] as String? ?? '',
      descriptionHtml: json['body_html'] as String?,
      productType: json['product_type'] as String?,
      vendor: json['vendor'] as String?,
      featuredImage:
          _image(json['image']) ?? (images.isEmpty ? null : images.first),
      images: images,
      variants: variants,
      options: [
        for (var i = 0; i < options.length; i++)
          ProductOption(
            id: 'public-option-$i',
            name: options[i]['name'] as String? ?? 'Option ${i + 1}',
            values: (options[i]['values'] as List? ?? const [])
                .whereType<String>()
                .toList(growable: false),
          ),
      ],
      tags: _tags(json['tags']),
      availableForSale: variants.any((variant) => variant.availableForSale),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }

  List<String> _tags(Object? value) {
    if (value is String) {
      return value
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList(growable: false);
    }
    if (value is List) return value.whereType<String>().toList(growable: false);
    return const [];
  }

  ProductImage? _image(Object? value) {
    if (value is! Map<String, Object?>) return null;
    final url = value['src'];
    if (url is! String || url.isEmpty) return null;
    return ProductImage(
      url: url,
      altText: value['alt'] as String?,
      width: value['width'] as int?,
      height: value['height'] as int?,
    );
  }
}
