/// Requests a display-sized variant from Shopify's image CDN.
///
/// Other hosts are left unchanged because their query parameters may be signed
/// or may not support Shopify's width transform.
String shopifyImageUrlForWidth(String imageUrl, int width) {
  final uri = Uri.tryParse(imageUrl);
  if (uri == null || uri.scheme != 'https') return imageUrl;
  final host = uri.host.toLowerCase();
  final isShopifyCdn =
      host == 'cdn.shopify.com' && uri.path.startsWith('/s/files/');
  final isStoreCdn =
      (host == 'flexwolf.co' || host == 'www.flexwolf.co') &&
      uri.path.startsWith('/cdn/shop/');
  if (!isShopifyCdn && !isStoreCdn) return imageUrl;
  final imageWidth = width.clamp(64, 1440);
  return uri
      .replace(
        queryParameters: {
          ...uri.queryParameters,
          'width': imageWidth.toString(),
        },
      )
      .toString();
}
