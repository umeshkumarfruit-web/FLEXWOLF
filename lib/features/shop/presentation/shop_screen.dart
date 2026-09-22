import 'package:flexwolf/app/router/route_names.dart';
import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/services/service_registry.dart';
import 'package:flexwolf/core/widgets/app_button.dart';
import 'package:flexwolf/core/widgets/app_empty_state.dart';
import 'package:flexwolf/core/widgets/app_error_state.dart';
import 'package:flexwolf/core/widgets/app_loading_indicator.dart';
import 'package:flexwolf/features/shop/data/shop_providers.dart';
import 'package:flexwolf/features/shop/domain/catalog_cache.dart';
import 'package:flexwolf/features/shop/domain/collection.dart';
import 'package:flexwolf/features/shop/domain/pagination.dart';
import 'package:flexwolf/features/shop/domain/product.dart';
import 'package:flexwolf/features/shop/domain/shop_repositories.dart';
import 'package:flexwolf/features/shop/presentation/product_page.dart';
import 'package:flexwolf/features/home/presentation/flexwolf_storefront_home.dart';
import 'package:flexwolf/integrations/analytics/analytics_boundary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _pageSize = 24;

enum ShopSortOption {
  featured,
  newest,
  bestSelling,
  priceLowHigh,
  priceHighLow,
}

class ShopFilters {
  const ShopFilters({this.size, this.color, this.availableOnly = false});
  final String? size;
  final String? color;
  final bool availableOnly;
  bool get hasActive => size != null || color != null || availableOnly;
  ShopFilters copyWith({String? size, String? color, bool? availableOnly}) =>
      ShopFilters(
        size: size ?? this.size,
        color: color ?? this.color,
        availableOnly: availableOnly ?? this.availableOnly,
      );
  static const empty = ShopFilters();
}

class ShopQueryState {
  const ShopQueryState({
    this.search = '',
    this.filters = ShopFilters.empty,
    this.sort = ShopSortOption.featured,
  });
  final String search;
  final ShopFilters filters;
  final ShopSortOption sort;
}

class ShopController extends ChangeNotifier {
  ShopController({
    required this.repository,
    required this.collectionRepository,
    required this.cache,
    required this.initialCollection,
    this.initialPageSize = _pageSize,
  });
  final ProductRepository repository;
  final CollectionRepository collectionRepository;
  final ShopCatalogCache cache;
  final ShopCollectionTab initialCollection;
  final int initialPageSize;
  AsyncValue<ShopState> state = const AsyncLoading<ShopState>();
  AsyncValue<List<ProductCollection>> collections =
      const AsyncLoading<List<ProductCollection>>();
  var query = const ShopQueryState();
  var _loadingMore = false;
  var _disposed = false;
  var _requestVersion = 0;
  ShopState? get current => state.maybeWhen(data: (v) => v, orElse: () => null);

  Future<void> loadInitial() async {
    final version = ++_requestVersion;
    await loadCollections();
    if (_disposed || version != _requestVersion) return;
    final result = await AsyncValue.guard(() => _load(initialCollection));
    if (_disposed || version != _requestVersion) return;
    state = result;
    _notify();
  }

  Future<void> loadCollections() async {
    final cached = cache.collections;
    if (cached != null) {
      collections = AsyncData(cached.result.items);
      _notify();
    }
    collections = await AsyncValue.guard(() async {
      final r = await collectionRepository.fetchCollections(
        const PaginationRequest(first: 24),
      );
      cache.collections = CachedPage(result: r, cachedAt: DateTime.now());
      return r.items;
    });
    _notify();
  }

  Future<void> selectCollection(ShopCollectionTab c) async {
    final version = ++_requestVersion;
    state = const AsyncLoading<ShopState>();
    _notify();
    final result = await AsyncValue.guard(() => _load(c));
    if (_disposed || version != _requestVersion) return;
    state = result;
    _notify();
  }

  Future<void> refresh() async {
    final version = ++_requestVersion;
    final result = await AsyncValue.guard(
      () => _load(current?.collection ?? initialCollection),
    );
    if (_disposed || version != _requestVersion) return;
    state = result;
    _notify();
  }

  void updateSearch(String v) {
    query = ShopQueryState(
      search: v.trim(),
      filters: query.filters,
      sort: query.sort,
    );
    _notify();
  }

  void updateSort(ShopSortOption v) {
    query = ShopQueryState(
      search: query.search,
      filters: query.filters,
      sort: v,
    );
    _notify();
  }

  void updateFilters(ShopFilters v) {
    query = ShopQueryState(search: query.search, filters: v, sort: query.sort);
    _notify();
  }

  void clearFilters() {
    query = ShopQueryState(search: query.search, sort: query.sort);
    _notify();
  }

  Future<void> loadMore({bool retry = false}) async {
    final c = current;
    if (c == null ||
        c.isLoadingMore ||
        !c.pageInfo.hasNextPage ||
        c.pageInfo.endCursor == null ||
        (c.loadMoreError != null && !retry) ||
        _loadingMore) {
      return;
    }
    final version = _requestVersion;
    _loadingMore = true;
    state = AsyncData(c.copyWith(isLoadingMore: true));
    _notify();
    try {
      final r = await _fetch(
        c.collection,
        PaginationRequest(first: _pageSize, after: c.pageInfo.endCursor),
      );
      if (_disposed || version != _requestVersion) return;
      final n = c.append(r);
      state = AsyncData(n);
      _write(n);
    } catch (e) {
      if (_disposed || version != _requestVersion) return;
      state = AsyncData(c.copyWith(isLoadingMore: false, loadMoreError: e));
    } finally {
      _loadingMore = false;
      if (version == _requestVersion) _notify();
    }
  }

  Future<ShopState> _load(ShopCollectionTab c) async {
    final key = _key(c);
    try {
      final r = await _fetch(c, PaginationRequest(first: initialPageSize));
      final s = ShopState(
        collection: c,
        products: r.items,
        pageInfo: r.pageInfo,
      );
      _write(s);
      return s;
    } catch (e) {
      final cached = cache.read(key);
      if (cached != null) {
        return ShopState(
          collection: c,
          products: cached.result.items,
          pageInfo: cached.result.pageInfo,
          isFromCache: true,
          loadMoreError: e,
        );
      }
      rethrow;
    }
  }

  Future<PaginatedResult<ProductSummary>> _fetch(
    ShopCollectionTab c,
    PaginationRequest p,
  ) => c.loadsAllProducts
      ? repository.fetchProducts(p)
      : repository.fetchProductsByCollection(
          collectionHandle: c.collectionHandle!,
          pagination: p,
        );
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void _write(ShopState s) => cache.write(
    _key(s.collection),
    CachedPage(
      result: PaginatedResult(items: s.products, pageInfo: s.pageInfo),
      cachedAt: DateTime.now(),
    ),
  );
  String _key(ShopCollectionTab c) =>
      '${cache.policy.environmentKey}:${c.id}:${c.collectionHandle ?? 'all'}';
}

class ShopState {
  const ShopState({
    required this.collection,
    required this.products,
    required this.pageInfo,
    this.isLoadingMore = false,
    this.isFromCache = false,
    this.loadMoreError,
  });
  final ShopCollectionTab collection;
  final List<ProductSummary> products;
  final PageInfo pageInfo;
  final bool isLoadingMore;
  final bool isFromCache;
  final Object? loadMoreError;
  ShopState copyWith({
    List<ProductSummary>? products,
    PageInfo? pageInfo,
    bool? isLoadingMore,
    Object? loadMoreError,
    bool clearLoadMoreError = false,
  }) => ShopState(
    collection: collection,
    products: products ?? this.products,
    pageInfo: pageInfo ?? this.pageInfo,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    isFromCache: isFromCache,
    loadMoreError: clearLoadMoreError
        ? null
        : loadMoreError ?? this.loadMoreError,
  );
  ShopState append(PaginatedResult<ProductSummary> r) {
    final seen = products.map((p) => p.id).toSet();
    final newProducts = <ProductSummary>[
      for (final product in r.items)
        if (seen.add(product.id)) product,
    ];
    final cursor = r.pageInfo.endCursor;
    final canContinue =
        newProducts.isNotEmpty &&
        r.pageInfo.hasNextPage &&
        cursor != null &&
        cursor != pageInfo.endCursor;
    return copyWith(
      products: [...products, ...newProducts],
      pageInfo: canContinue ? r.pageInfo : const PageInfo(hasNextPage: false),
      isLoadingMore: false,
      clearLoadMoreError: true,
    );
  }
}

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({this.searchMode = false, this.collectionHandle, super.key});
  final bool searchMode;
  final String? collectionHandle;
  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  late final ShopController _c;
  final _tracked = <String>{};

  @override
  void initState() {
    super.initState();
    _c = ShopController(
      repository: ref.read(productRepositoryProvider),
      collectionRepository: ref.read(collectionRepositoryProvider),
      cache: ref.read(shopCatalogCacheProvider),
      initialPageSize: 250,
      initialCollection: widget.collectionHandle == null
          ? ref.read(shopCollectionConfigProvider).first
          : ShopCollectionTab(
              id: widget.collectionHandle!,
              label: widget.collectionHandle!.replaceAll('-', ' '),
              collectionHandle: widget.collectionHandle,
            ),
    )..addListener(_changed);
    _c.loadInitial();
  }

  @override
  void dispose() {
    _c.removeListener(_changed);
    _c.dispose();
    super.dispose();
  }

  void _changed() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final handle = GoRouterState.of(context).uri.queryParameters['product'];
    if (handle != null && handle.isNotEmpty) {
      return ProductPage(handle: handle);
    }
    final tabs = ref.watch(shopCollectionConfigProvider);
    final active = _c.current?.collection ?? tabs.first;
    final visible = _visible(_c.current?.products ?? const []);
    return Semantics(
      label: 'Shop',
      explicitChildNodes: true,
      scopesRoute: true,
      namesRoute: true,
      child: RefreshIndicator(
        onRefresh: _c.refresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _ShopHeader(
                searchMode: widget.searchMode,
                tabs: tabs,
                active: active,
                collections: _c.collections,
                query: _c.query,
                products: _c.current?.products ?? const [],
                onSelect: _selectCollection,
                onRetryCollections: _c.loadCollections,
                onSearchChanged: _search,
                onSortChanged: _sort,
                onFiltersChanged: _filters,
                onClearFilters: _clearFilters,
              ),
            ),
            _c.state.when(
              loading: () => const _ShopSkeletonGrid(),
              error: (e, s) => SliverFillRemaining(
                hasScrollBody: false,
                child: AppErrorState(
                  error: e is AppException ? e : mapUnknownException(e),
                  onRetry: _c.loadInitial,
                ),
              ),
              data: (v) {
                _trackLoaded(v.collection);
                if (visible.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyState(
                      title: 'No products found',
                      message: 'Clear filters or try another collection.',
                      icon: Icons.inventory_2_outlined,
                    ),
                  );
                }
                return _ProductGrid(
                  state: v.copyWith(products: visible),
                  onProductTap: _openProduct,
                );
              },
            ),
            SliverToBoxAdapter(
              child: _LoadMoreFooter(
                state: _c.current,
                onLoadMore: () => _c.loadMore(retry: true),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
          ],
        ),
      ),
    );
  }

  void _search(String v) {
    _c.updateSearch(v);
    ref
        .read(analyticsGatewayProvider)
        .track(const AnalyticsEvent(name: 'search'));
  }

  void _sort(ShopSortOption v) {
    _c.updateSort(v);
    ref
        .read(analyticsGatewayProvider)
        .track(const AnalyticsEvent(name: 'sort_changed'));
  }

  void _filters(ShopFilters v) {
    _c.updateFilters(v);
    ref
        .read(analyticsGatewayProvider)
        .track(const AnalyticsEvent(name: 'filter_applied'));
  }

  void _clearFilters() {
    _c.clearFilters();
    ref
        .read(analyticsGatewayProvider)
        .track(const AnalyticsEvent(name: 'filter_cleared'));
  }

  void _selectCollection(ShopCollectionTab c) {
    ref
        .read(analyticsGatewayProvider)
        .track(const AnalyticsEvent(name: 'collection_open'));
    _c.selectCollection(c);
  }

  void _trackLoaded(ShopCollectionTab c) {
    if (_tracked.add(c.id)) {
      ref
          .read(analyticsGatewayProvider)
          .track(const AnalyticsEvent(name: 'collection_loaded'));
    }
  }

  void _openProduct(ProductSummary p) {
    ref
        .read(analyticsGatewayProvider)
        .track(const AnalyticsEvent(name: 'collection_product_click'));
    context.goNamed(
      AppRouteNames.product,
      pathParameters: {'handle': p.handle},
    );
  }

  List<ProductSummary> _visible(List<ProductSummary> products) {
    final q = _c.query;
    Iterable<ProductSummary> r = products;
    if (q.search.isNotEmpty) {
      final n = q.search.toLowerCase();
      r = r.where((p) => _matchesSearch(p, n));
    }
    if (q.filters.availableOnly) {
      r = r.where((p) => p.availableForSale);
    }
    if (q.filters.size != null) {
      r = r.where(
        (p) => p.variants.any((v) => _sameOption(v.size, q.filters.size)),
      );
    }
    if (q.filters.color != null) {
      r = r.where(
        (p) => p.variants.any((v) => _sameOption(v.color, q.filters.color)),
      );
    }
    final list = r.toList();
    num price(ProductSummary p) =>
        num.tryParse(
          p.variants.isEmpty ? '' : p.variants.first.price.amount.value,
        ) ??
        0;
    switch (q.sort) {
      case ShopSortOption.newest:
        list.sort(
          (a, b) => (b.updatedAt ?? DateTime(0)).compareTo(
            a.updatedAt ?? DateTime(0),
          ),
        );
      case ShopSortOption.priceLowHigh:
        list.sort((a, b) => price(a).compareTo(price(b)));
      case ShopSortOption.priceHighLow:
        list.sort((a, b) => price(b).compareTo(price(a)));
      case ShopSortOption.featured:
      case ShopSortOption.bestSelling:
        break;
    }
    return list;
  }
}

class _ShopHeader extends StatelessWidget {
  const _ShopHeader({
    this.searchMode = false,
    required this.tabs,
    required this.active,
    required this.collections,
    required this.query,
    required this.products,
    required this.onSelect,
    required this.onRetryCollections,
    required this.onSearchChanged,
    required this.onSortChanged,
    required this.onFiltersChanged,
    required this.onClearFilters,
  });
  final List<ShopCollectionTab> tabs;
  final ShopCollectionTab active;
  final AsyncValue<List<ProductCollection>> collections;
  final ShopQueryState query;
  final List<ProductSummary> products;
  final ValueChanged<ShopCollectionTab> onSelect;
  final VoidCallback onRetryCollections;
  final bool searchMode;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<ShopSortOption> onSortChanged;
  final ValueChanged<ShopFilters> onFiltersChanged;
  final VoidCallback onClearFilters;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(8, 12, 8, 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (searchMode) ...[
          TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search for...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: onSearchChanged,
          ),
          const SizedBox(height: 18),
        ],
        Row(
          children: [
            Expanded(
              child: Text(
                searchMode ? 'Search' : active.label,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            PopupMenuButton<ShopSortOption>(
              tooltip: 'Sort products',
              icon: const Icon(Icons.swap_vert),
              onSelected: onSortChanged,
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: ShopSortOption.featured,
                  child: Text('Featured'),
                ),
                PopupMenuItem(
                  value: ShopSortOption.newest,
                  child: Text('Newest'),
                ),
                PopupMenuItem(
                  value: ShopSortOption.priceLowHigh,
                  child: Text('Price: low to high'),
                ),
                PopupMenuItem(
                  value: ShopSortOption.priceHighLow,
                  child: Text('Price: high to low'),
                ),
              ],
            ),
            SizedBox(
              width: 112,
              child: OutlinedButton.icon(
                onPressed: () => _showFilters(context),
                icon: const Icon(Icons.tune, size: 18),
                label: const Text('Filter +'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.black,
                  side: const BorderSide(color: AppColors.black),
                  shape: const RoundedRectangleBorder(),
                ),
              ),
            ),
          ],
        ),
        if (query.filters.hasActive) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              if (query.filters.size != null)
                Chip(label: Text('Size ${query.filters.size}')),
              if (query.filters.color != null)
                Chip(label: Text(query.filters.color!)),
              if (query.filters.availableOnly)
                const Chip(label: Text('In stock')),
              ActionChip(label: const Text('Clear'), onPressed: onClearFilters),
            ],
          ),
        ],
      ],
    ),
  );
  void _showFilters(BuildContext context) {
    final sizes =
        products
            .expand((p) => p.variants.map((v) => v.size))
            .whereType<String>()
            .toSet()
            .toList()
          ..sort();
    final colors =
        products
            .expand((p) => p.variants.map((v) => v.color))
            .whereType<String>()
            .toSet()
            .toList()
          ..sort();
    var draft = query.filters;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) {
          final viewInsets = MediaQuery.viewInsetsOf(context);
          final maxHeight = MediaQuery.sizeOf(context).height * 0.82;
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(bottom: viewInsets.bottom),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Filters',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Available only',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        value: draft.availableOnly,
                        onChanged: (v) => setSheet(
                          () => draft = draft.copyWith(availableOnly: v),
                        ),
                      ),
                      if (sizes.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: draft.size,
                          decoration: const InputDecoration(labelText: 'Size'),
                          items: sizes
                              .map(
                                (v) => DropdownMenuItem(
                                  value: v,
                                  child: Text(
                                    v,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setSheet(
                            () => draft = ShopFilters(
                              size: v,
                              color: draft.color,
                              availableOnly: draft.availableOnly,
                            ),
                          ),
                        ),
                      ],
                      if (colors.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.sm),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: draft.color,
                          decoration: const InputDecoration(labelText: 'Color'),
                          items: colors
                              .map(
                                (v) => DropdownMenuItem(
                                  value: v,
                                  child: Text(
                                    v,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setSheet(
                            () => draft = ShopFilters(
                              size: draft.size,
                              color: v,
                              availableOnly: draft.availableOnly,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton.secondary(
                              label: 'Clear',
                              icon: Icons.clear,
                              onPressed: () =>
                                  setSheet(() => draft = ShopFilters.empty),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: AppButton.primary(
                              label: 'Apply',
                              icon: Icons.check,
                              onPressed: () {
                                onFiltersChanged(draft);
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({required this.state, required this.onProductTap});
  final ShopState state;
  final ValueChanged<ProductSummary> onProductTap;
  @override
  Widget build(BuildContext context) => SliverGrid.builder(
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 220,
      mainAxisSpacing: AppSpacing.xl,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisExtent: 340,
    ),
    itemCount: state.products.length,
    itemBuilder: (context, i) {
      final p = state.products[i];
      return StorefrontProductCard(
        key: ValueKey(p.id),
        product: p,
        onProductTap: onProductTap,
      );
    },
  );
}

class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({required this.state, required this.onLoadMore});
  final ShopState? state;
  final VoidCallback onLoadMore;
  @override
  Widget build(BuildContext context) =>
      state == null || state!.products.isEmpty || !state!.pageInfo.hasNextPage
      ? const SizedBox.shrink()
      : Padding(
          padding: const EdgeInsets.only(top: AppSpacing.lg),
          child: Center(
            child: state!.isLoadingMore
                ? const AppSkeletonLoader(width: 160, height: 44)
                : AppButton.secondary(
                    label: state!.loadMoreError == null ? 'Load More' : 'Retry',
                    icon: Icons.expand_more,
                    onPressed: onLoadMore,
                  ),
          ),
        );
}

class _ShopSkeletonGrid extends StatelessWidget {
  const _ShopSkeletonGrid();
  @override
  Widget build(BuildContext context) => SliverGrid.builder(
    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 220,
      mainAxisSpacing: AppSpacing.xl,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisExtent: 340,
    ),
    itemCount: 6,
    itemBuilder: (_, _) => const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSkeletonLoader(height: 220),
        SizedBox(height: AppSpacing.sm),
        AppSkeletonLoader(height: 18),
        SizedBox(height: AppSpacing.xs),
        AppSkeletonLoader(width: 96, height: 16),
      ],
    ),
  );
}

bool _matchesSearch(ProductSummary p, String query) {
  final values = <String>[
    p.title,
    p.handle,
    if (p.description != null) p.description!,
    if (p.productType != null) p.productType!,
    if (p.vendor != null) p.vendor!,
    ...p.tags,
    for (final variant in p.variants) ...[
      if (variant.title != null) variant.title!,
      if (variant.size != null) variant.size!,
      if (variant.color != null) variant.color!,
    ],
  ];

  return values.any((value) => value.toLowerCase().contains(query));
}

bool _sameOption(String? value, String? selected) =>
    value?.trim().toLowerCase() == selected?.trim().toLowerCase();
