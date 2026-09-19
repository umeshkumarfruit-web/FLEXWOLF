import 'package:flexwolf/app/router/route_names.dart';

abstract final class AppDeepLinks {
  static const productPrefix = '/products';
  static const collectionPrefix = '/collections';
  static const cart = '/cart';
  static const checkout = '/checkout';
  static const dropsPrefix = '/drops';
  static const offersPrefix = '/offers';
  static const wishlist = '/wishlist';
  static const account = '/account';
  static const customerProfile = '/account/profile';
  static const orders = '/account/orders';
  static const orderPrefix = '/account/orders';
  static const fallback = '/link-unavailable';
}

enum DeepLinkDestination {
  home,
  product,
  collection,
  wishlist,
  cart,
  checkout,
  orderDetails,
  customerProfile,
  promotion,
  invalid,
}

class DeepLinkResolution {
  const DeepLinkResolution({
    required this.destination,
    required this.route,
    required this.originalLink,
    this.identifier,
    this.fallbackReason,
  });

  final DeepLinkDestination destination;
  final String route;
  final String originalLink;
  final String? identifier;
  final String? fallbackReason;

  bool get isValid => destination != DeepLinkDestination.invalid;
}

class DeepLinkParser {
  const DeepLinkParser();

  DeepLinkResolution parse(String? rawLink) {
    final link = rawLink?.trim();
    if (link == null || link.isEmpty || link.length > 512) {
      return _invalid(rawLink ?? '', 'missing_or_too_long');
    }
    final uri = Uri.tryParse(link);
    if (uri == null || (uri.hasScheme && !_allowedScheme(uri.scheme))) {
      return _invalid(link, 'unsupported_scheme');
    }
    final path = _normalizePath(
      uri.hasScheme ? uri.path : link.split('?').first,
    );
    final segments = path.split('/').where((part) => part.isNotEmpty).toList();
    if (path == AppRoutes.search || path == AppRoutes.shop) {
      return DeepLinkResolution(
        destination: DeepLinkDestination.home,
        route: path,
        originalLink: link,
      );
    }
    if (path == AppRoutes.home) {
      return const DeepLinkResolution(
        destination: DeepLinkDestination.home,
        route: AppRoutes.home,
        originalLink: AppRoutes.home,
      );
    }
    if (path == AppDeepLinks.wishlist) {
      return DeepLinkResolution(
        destination: DeepLinkDestination.wishlist,
        route: AppRoutes.wishlist,
        originalLink: link,
      );
    }
    if (path == AppDeepLinks.cart) {
      return DeepLinkResolution(
        destination: DeepLinkDestination.cart,
        route: AppDeepLinks.cart,
        originalLink: link,
      );
    }
    if (path == AppDeepLinks.checkout) {
      return DeepLinkResolution(
        destination: DeepLinkDestination.checkout,
        route: AppDeepLinks.checkout,
        originalLink: link,
      );
    }
    if (path == AppDeepLinks.account || path == AppDeepLinks.customerProfile) {
      return DeepLinkResolution(
        destination: DeepLinkDestination.customerProfile,
        route: AppRoutes.account,
        originalLink: link,
      );
    }
    if (segments.length >= 2 && segments[0] == 'products') {
      return _idRoute(
        DeepLinkDestination.product,
        '${AppRoutes.shop}${AppDeepLinks.productPrefix}/${segments[1]}',
        link,
        segments[1],
        'missing_product',
      );
    }
    if (segments.length >= 3 &&
        segments[0] == 'shop' &&
        segments[1] == 'products') {
      return _idRoute(
        DeepLinkDestination.product,
        path,
        link,
        segments[2],
        'missing_product',
      );
    }
    if (segments.length >= 2 && segments[0] == 'collections') {
      return _idRoute(
        DeepLinkDestination.collection,
        '${AppRoutes.shop}${AppDeepLinks.collectionPrefix}/${segments[1]}',
        link,
        segments[1],
        'deleted_collection',
      );
    }
    if (segments.length >= 3 &&
        segments[0] == 'account' &&
        segments[1] == 'orders') {
      return _idRoute(
        DeepLinkDestination.orderDetails,
        AppRoutes.account,
        link,
        segments[2],
        'invalid_order',
      );
    }
    if (path == AppDeepLinks.orders) {
      return DeepLinkResolution(
        destination: DeepLinkDestination.orderDetails,
        route: AppRoutes.account,
        originalLink: link,
      );
    }
    if (segments.length >= 2 &&
        (segments[0] == 'offers' || segments[0] == 'drops')) {
      return _idRoute(
        DeepLinkDestination.promotion,
        '${AppRoutes.shop}/promotions/${segments[1]}',
        link,
        segments[1],
        'promotion_unavailable',
      );
    }
    return _invalid(link, 'unknown_route');
  }

  DeepLinkResolution _idRoute(
    DeepLinkDestination destination,
    String route,
    String originalLink,
    String identifier,
    String fallbackReason,
  ) {
    if (!_safeIdentifier(identifier)) {
      return _fallback(destination, originalLink, fallbackReason);
    }
    return DeepLinkResolution(
      destination: destination,
      route: route,
      originalLink: originalLink,
      identifier: identifier,
    );
  }

  DeepLinkResolution _fallback(
    DeepLinkDestination destination,
    String originalLink,
    String reason,
  ) => DeepLinkResolution(
    destination: destination,
    route: '${AppDeepLinks.fallback}?reason=$reason',
    originalLink: originalLink,
    fallbackReason: reason,
  );

  DeepLinkResolution _invalid(String originalLink, String reason) =>
      _fallback(DeepLinkDestination.invalid, originalLink, reason);
}

bool _allowedScheme(String scheme) => scheme == 'flexwolf' || scheme == 'https';

bool _safeIdentifier(String value) =>
    RegExp(r'^[A-Za-z0-9][A-Za-z0-9._~-]{0,127}$').hasMatch(value);

String _normalizePath(String path) {
  final clean = path.trim().isEmpty ? AppRoutes.home : path.trim();
  final prefixed = clean.startsWith('/') ? clean : '/$clean';
  return prefixed.endsWith('/') && prefixed.length > 1
      ? prefixed.substring(0, prefixed.length - 1)
      : prefixed;
}
