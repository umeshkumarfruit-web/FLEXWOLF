class PageInfo {
  const PageInfo({required this.hasNextPage, this.endCursor});

  factory PageInfo.fromShopify(Map<String, Object?> json) {
    final hasNextPage = json['hasNextPage'];
    if (hasNextPage is! bool) {
      throw const FormatException('Invalid Shopify pageInfo payload.');
    }
    return PageInfo(
      hasNextPage: hasNextPage,
      endCursor: json['endCursor'] as String?,
    );
  }

  final bool hasNextPage;
  final String? endCursor;
}

class PaginatedResult<T> {
  const PaginatedResult({
    required this.items,
    required this.pageInfo,
    this.error,
  });

  final List<T> items;
  final PageInfo pageInfo;
  final Object? error;

  PaginatedResult<T> append(
    PaginatedResult<T> next,
    String Function(T item) idOf,
  ) {
    final byId = <String, T>{for (final item in items) idOf(item): item};
    for (final item in next.items) {
      byId[idOf(item)] = item;
    }
    return PaginatedResult<T>(
      items: byId.values.toList(growable: false),
      pageInfo: next.pageInfo,
      error: next.error,
    );
  }
}

class PaginationRequest {
  const PaginationRequest({this.first = 20, this.after});

  final int first;
  final String? after;
}
