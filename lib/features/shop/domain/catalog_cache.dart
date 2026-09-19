import 'package:flexwolf/features/shop/domain/pagination.dart';

class CatalogCachePolicy {
  const CatalogCachePolicy({
    required this.maxEntries,
    required this.staleAfter,
    required this.environmentKey,
  });

  final int maxEntries;
  final Duration staleAfter;
  final String environmentKey;
}

class CachedPage<T> {
  const CachedPage({required this.result, required this.cachedAt});

  final PaginatedResult<T> result;
  final DateTime cachedAt;

  bool isStale(CatalogCachePolicy policy, DateTime now) {
    return now.difference(cachedAt) > policy.staleAfter;
  }
}
