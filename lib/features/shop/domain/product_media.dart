class ProductMedia {
  const ProductMedia({
    required this.id,
    required this.kind,
    this.url,
    this.altText,
    this.previewImage,
  });

  factory ProductMedia.fromShopify(Map<String, Object?> json) {
    final mediaContentType = json['mediaContentType'];
    final id = json['id'];
    if (id is! String) {
      throw const FormatException('Shopify media is missing id.');
    }

    final image = _asMap(json['image']);
    final preview = _asMap(json['previewImage']);
    return ProductMedia(
      id: id,
      kind: ProductMediaKind.fromShopify(mediaContentType),
      url: _string(image?['url']) ?? _string(json['sourcesUrl']),
      altText: _string(image?['altText']) ?? _string(json['alt']),
      previewImage: preview == null ? null : ProductImage.fromShopify(preview),
    );
  }

  final String id;
  final ProductMediaKind kind;
  final String? url;
  final String? altText;
  final ProductImage? previewImage;
}

class ProductImage {
  const ProductImage({
    required this.url,
    this.altText,
    this.width,
    this.height,
  });

  factory ProductImage.fromShopify(Map<String, Object?> json) {
    final url = json['url'];
    if (url is! String) {
      throw const FormatException('Shopify image is missing url.');
    }

    return ProductImage(
      url: url,
      altText: _string(json['altText']),
      width: _int(json['width']),
      height: _int(json['height']),
    );
  }

  final String url;
  final String? altText;
  final int? width;
  final int? height;
}

enum ProductMediaKind {
  image,
  video,
  externalVideo,
  model3d,
  unknown;

  factory ProductMediaKind.fromShopify(Object? value) {
    return switch (value) {
      'IMAGE' => ProductMediaKind.image,
      'VIDEO' => ProductMediaKind.video,
      'EXTERNAL_VIDEO' => ProductMediaKind.externalVideo,
      'MODEL_3D' => ProductMediaKind.model3d,
      _ => ProductMediaKind.unknown,
    };
  }
}

Map<String, Object?>? _asMap(Object? value) =>
    value is Map<String, Object?> ? value : null;
String? _string(Object? value) => value is String ? value : null;
int? _int(Object? value) => value is int ? value : null;
