import 'dart:async';

import 'package:flexwolf/app/router/route_names.dart';
import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/services/service_registry.dart';
import 'package:flexwolf/core/widgets/app_badge.dart';
import 'package:flexwolf/core/widgets/app_button.dart';
import 'package:flexwolf/core/widgets/app_empty_state.dart';
import 'package:flexwolf/core/widgets/app_error_state.dart';
import 'package:flexwolf/core/widgets/app_loading_indicator.dart';
import 'package:flexwolf/core/widgets/app_price.dart';
import 'package:flexwolf/core/widgets/app_product_card_shell.dart';
import 'package:flexwolf/core/widgets/app_remote_image.dart';
import 'package:flexwolf/features/shop/data/shop_providers.dart';
import 'package:flexwolf/features/shop/domain/catalog_cache.dart';
import 'package:flexwolf/features/shop/domain/collection.dart';
import 'package:flexwolf/features/shop/domain/money.dart';
import 'package:flexwolf/features/shop/domain/pagination.dart';
import 'package:flexwolf/features/shop/domain/product.dart';
import 'package:flexwolf/features/shop/domain/shop_repositories.dart';
import 'package:flexwolf/features/shop/presentation/product_page.dart';
import 'package:flexwolf/integrations/analytics/analytics_boundary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

const _pageSize = 250;

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
  });
  final ProductRepository repository;
  final CollectionRepository collectionRepository;
  final ShopCatalogCache cache;
  final ShopCollectionTab initialCollection;
  AsyncValue<ShopState> state = const AsyncLoading<ShopState>();
  AsyncValue<List<ProductCollection>> collections =
      const AsyncLoading<List<ProductCollection>>();
  var query = const ShopQueryState();
  var _loadingMore = false;
  var _disposed = false;
  ShopState? get current => state.maybeWhen(data: (v) => v, orElse: () => null);

  Future<void> loadInitial() async {
    await loadCollections();
    if (_disposed) return;
    state = await AsyncValue.guard(() => _load(initialCollection));
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
    state = const AsyncLoading<ShopState>();
    _notify();
    state = await AsyncValue.guard(() => _load(c));
    _notify();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => _load(current?.collection ?? initialCollection),
    );
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

  Future<void> loadMore() async {
    final c = current;
    if (c == null ||
        c.isLoadingMore ||
        !c.pageInfo.hasNextPage ||
        _loadingMore) {
      return;
    }
    _loadingMore = true;
    state = AsyncData(c.copyWith(isLoadingMore: true));
    _notify();
    try {
      final r = await _fetch(
        c.collection,
        PaginationRequest(first: _pageSize, after: c.pageInfo.endCursor),
      );
      final n = c.append(r);
      state = AsyncData(n);
      _write(n);
    } catch (e) {
      state = AsyncData(c.copyWith(isLoadingMore: false, loadMoreError: e));
    } finally {
      _loadingMore = false;
      _notify();
    }
  }

  Future<ShopState> _load(ShopCollectionTab c) async {
    final key = _key(c);
    try {
      var r = await _fetch(c, const PaginationRequest(first: _pageSize));
      final products = <ProductSummary>[...r.items];
      final seen = products.map((product) => product.id).toSet();
      while (r.pageInfo.hasNextPage && r.pageInfo.endCursor != null) {
        final next = await _fetch(
          c,
          PaginationRequest(first: _pageSize, after: r.pageInfo.endCursor),
        );
        for (final product in next.items) {
          if (seen.add(product.id)) products.add(product);
        }
        if (next.pageInfo.endCursor == r.pageInfo.endCursor) break;
        r = next;
      }
      final s = ShopState(
        collection: c,
        products: products,
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
    bool? isLoadingMore,
    Object? loadMoreError,
  }) => ShopState(
    collection: collection,
    products: products ?? this.products,
    pageInfo: pageInfo,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    isFromCache: isFromCache,
    loadMoreError: loadMoreError ?? this.loadMoreError,
  );
  ShopState append(PaginatedResult<ProductSummary> r) {
    final seen = products.map((p) => p.id).toSet();
    return copyWith(
      products: [
        ...products,
        for (final p in r.items)
          if (seen.add(p.id)) p,
      ],
      isLoadingMore: false,
    );
  }
}

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({this.searchMode = false, super.key});
  final bool searchMode;
  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  final _scroll = ScrollController();
  late final ShopController _c;
  Timer? _debounce;
  final _tracked = <String>{};

  @override
  void initState() {
    super.initState();
    _c = ShopController(
      repository: ref.read(productRepositoryProvider),
      collectionRepository: ref.read(collectionRepositoryProvider),
      cache: ref.read(shopCatalogCacheProvider),
      initialCollection: ref.read(shopCollectionConfigProvider).first,
    )..addListener(_changed);
    _c.loadInitial();
    _scroll.addListener(() {
      if (_scroll.hasClients && _scroll.position.extentAfter < 600) {
        _c.loadMore();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
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
          controller: _scroll,
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
                onLoadMore: _c.loadMore,
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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        color: AppColors.black,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FLEXWOLF / SHOP',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'PERFORMANCE, WITHOUT COMPROMISE.',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Performance essentials from FLEXWOLF.',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: AppColors.neutral200),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: const [
          Chip(label: Text('FREE SHIPPING \$75+')),
          Chip(label: Text('60-DAY RETURNS')),
          Chip(label: Text('TRUST LIKE A WOLF')),
        ],
      ),
      const SizedBox(height: AppSpacing.lg),
      DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.neutral900
              : AppColors.neutral50,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      autofocus: searchMode,
                      decoration: const InputDecoration(
                        labelText: 'Search products',
                        hintText: 'Name, color, size, tag',
                        prefixIcon: Icon(Icons.search),
                      ),
                      textInputAction: TextInputAction.search,
                      onChanged: onSearchChanged,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<ShopSortOption>(
                      isExpanded: true,
                      initialValue: query.sort,
                      decoration: const InputDecoration(labelText: 'Sort'),
                      items: const [
                        DropdownMenuItem(
                          value: ShopSortOption.featured,
                          child: Text(
                            'Featured',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: ShopSortOption.newest,
                          child: Text(
                            'Newest',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: ShopSortOption.bestSelling,
                          child: Text(
                            'Best Selling',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: ShopSortOption.priceLowHigh,
                          child: Text(
                            'Price Low to High',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        DropdownMenuItem(
                          value: ShopSortOption.priceHighLow,
                          child: Text(
                            'Price High to Low',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) {
                          onSortChanged(v);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SizedBox(
                    width: 128,
                    child: AppButton.secondary(
                      label: 'Filters',
                      icon: Icons.tune,
                      onPressed: () => _showFilters(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      if (query.filters.hasActive) ...[
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          children: [
            if (query.filters.size != null)
              Chip(label: Text('Size ${query.filters.size}')),
            if (query.filters.color != null)
              Chip(label: Text(query.filters.color!)),
            if (query.filters.availableOnly)
              const Chip(label: Text('Available')),
            ActionChip(label: const Text('Clear'), onPressed: onClearFilters),
          ],
        ),
      ],
      const SizedBox(height: AppSpacing.lg),
      Text(
        '${products.length} PRODUCTS',
        style: Theme.of(context).textTheme.labelMedium,
      ),
      const SizedBox(height: AppSpacing.sm),
      Text('COLLECTIONS', style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: AppSpacing.sm),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final tab in tabs) ...[
              ChoiceChip(
                label: Text(tab.label),
                selected: tab.id == active.id,
                onSelected: (_) => onSelect(tab),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      collections.when(
        loading: () => const _CollectionSkeletonRail(),
        error: (e, s) => AppErrorState(
          error: e is AppException ? e : mapUnknownException(e),
          onRetry: onRetryCollections,
        ),
        data: (items) => _CollectionRail(
          tabs: tabs,
          collections: items,
          active: active,
          onSelect: onSelect,
        ),
      ),
      const SizedBox(height: AppSpacing.lg),
    ],
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

class _CollectionRail extends StatelessWidget {
  const _CollectionRail({
    required this.tabs,
    required this.collections,
    required this.active,
    required this.onSelect,
  });
  final List<ShopCollectionTab> tabs;
  final List<ProductCollection> collections;
  final ShopCollectionTab active;
  final ValueChanged<ShopCollectionTab> onSelect;
  @override
  Widget build(BuildContext context) {
    final configured = tabs.where((t) => t.collectionHandle != null).toList();
    final cards = <Widget>[
      _CollectionCard(
        title: tabs.first.label,
        subtitle: 'Browse every available product',
        selected: active.id == tabs.first.id,
        onTap: () => onSelect(tabs.first),
      ),
      for (final c in collections)
        _CollectionCard(
          title: c.title,
          subtitle: c.description,
          imageUrl: c.image?.url,
          selected: active.collectionHandle == c.handle,
          onTap: () => onSelect(
            configured.firstWhere(
              (t) => t.collectionHandle == c.handle,
              orElse: () => ShopCollectionTab(
                id: c.handle,
                label: c.title,
                collectionHandle: c.handle,
              ),
            ),
          ),
        ),
    ];
    if (cards.length == 1) {
      return const AppEmptyState(
        title: 'Collections unavailable',
        message: 'Pull to refresh or try again.',
        icon: Icons.collections_bookmark_outlined,
      );
    }
    return SizedBox(
      height: 176,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (_, i) => SizedBox(width: 220, child: cards[i]),
      ),
    );
  }
}

class _CollectionCard extends StatelessWidget {
  const _CollectionCard({
    required this.title,
    required this.onTap,
    this.subtitle,
    this.imageUrl,
    this.selected = false,
  });
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: subtitle == null ? title : '$title, $subtitle',
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: selected ? AppColors.black : AppColors.divider,
          ),
          borderRadius: BorderRadius.circular(AppRadii.sm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: imageUrl == null
                  ? const Center(
                      child: Icon(Icons.collections_bookmark_outlined),
                    )
                  : AppRemoteImage(imageUrl: imageUrl!, semanticLabel: title),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CollectionSkeletonRail extends StatelessWidget {
  const _CollectionSkeletonRail();
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 176,
    child: Row(
      children: [
        Expanded(child: AppSkeletonLoader()),
        SizedBox(width: AppSpacing.md),
        Expanded(child: AppSkeletonLoader()),
      ],
    ),
  );
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
      final v = p.variants.isEmpty ? null : p.variants.first;
      final cmp = v?.compareAtPrice;
      final sale = v != null && isDiscountedPrice(v.price, cmp);
      return AppProductCardShell(
        title: p.title,
        image: p.featuredImage == null
            ? const Center(child: Icon(Icons.image_outlined))
            : AppRemoteImage(
                imageUrl: p.featuredImage!.url,
                semanticLabel: p.featuredImage!.altText ?? p.title,
              ),
        badge: sale
            ? const AppBadge(label: 'SALE', tone: AppBadgeTone.sale)
            : null,
        subtitle: p.availableForSale ? 'Available' : 'Sold out',
        price: AppPrice(
          price: _formatMoney(v?.price),
          compareAtPrice: sale ? _formatMoney(cmp) : null,
        ),
        semanticLabel:
            '${p.title}, ${p.availableForSale ? 'available' : 'sold out'}',
        onTap: () => onProductTap(p),
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
                    label: 'Load More',
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

String _formatMoney(Money? money) => money == null
    ? 'Price unavailable'
    : '${money.currencyCode} ${money.amount.value}';
