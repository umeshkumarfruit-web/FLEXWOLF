import 'package:flexwolf/core/connectivity/connectivity_service.dart';
import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/services/service_registry.dart';
import 'package:flexwolf/core/widgets/app_button.dart';
import 'package:flexwolf/core/widgets/app_empty_state.dart';
import 'package:flexwolf/core/widgets/app_error_state.dart';
import 'package:flexwolf/core/widgets/app_loading_indicator.dart';
import 'package:flexwolf/core/widgets/app_network_status_banner.dart';
import 'package:flexwolf/features/account/data/account_providers.dart';
import 'package:flexwolf/features/account/domain/customer.dart';
import 'package:flexwolf/features/account/domain/customer_order.dart';
import 'package:flexwolf/features/returns/domain/return_exchange_models.dart';
import 'package:flexwolf/features/returns/presentation/return_exchange_screen.dart';
import 'package:flexwolf/features/shop/domain/money.dart';
import 'package:flexwolf/features/shop/domain/pagination.dart';
import 'package:flexwolf/features/support/domain/support_models.dart';
import 'package:flexwolf/features/support/presentation/support_screen.dart';
import 'package:flexwolf/integrations/analytics/analytics_boundary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({this.embedded = false, super.key});

  final bool embedded;

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  final _orders = <CustomerOrder>[];
  PageInfo? _pageInfo;
  bool _loading = true;
  bool _loadingOrders = false;
  bool _loadingMore = false;
  bool _offline = false;
  AppException? _error;

  @override
  void initState() {
    super.initState();
    _load(refresh: true, trackView: true);
  }

  Future<void> _load({bool refresh = false, bool trackView = false}) async {
    if (_loadingOrders || _loadingMore) return;
    _loadingOrders = true;
    setState(() {
      if (refresh) _loading = true;
      _error = null;
    });
    try {
      final connectivity = await ref
          .read(connectivityServiceProvider)
          .current();
      _offline = connectivity.quality == ConnectivityQuality.offline;
      if (_offline && _orders.isEmpty) {
        throw const AppException(
          kind: AppErrorKind.network,
          message: 'Orders cannot refresh while offline.',
          code: 'orders_offline',
          isRetryable: true,
        );
      }
      final result = await ref
          .read(customerAccountRepositoryProvider)
          .fetchOrders(
            PaginationRequest(
              first: 20,
              after: refresh ? null : _pageInfo?.endCursor,
            ),
          );
      final next =
          [...(refresh ? const <CustomerOrder>[] : _orders), ...result.items]
            ..sort(
              (a, b) =>
                  (b.processedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
                      .compareTo(
                        a.processedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
                      ),
            );
      _orders
        ..clear()
        ..addAll(next);
      _pageInfo = result.pageInfo;
      if (trackView) _track(AppAnalyticsEvents.ordersViewed);
    } catch (error) {
      _error = error is AppException ? error : mapUnknownException(error);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
          _loadingOrders = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (!(_pageInfo?.hasNextPage ?? false)) return;
    setState(() => _loadingMore = true);
    await _load();
  }

  void _openOrder(CustomerOrder order) {
    _track(AppAnalyticsEvents.orderOpened);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _OrderDetailsSheet(
        order: order,
        onTrack: () => _track(AppAnalyticsEvents.trackingOpened),
        onReorder: () => _track(AppAnalyticsEvents.reorderClicked),
        onReturn: () => _openReturnExchange(order, ReturnFlowType.returnOnly),
        onExchange: () => _openReturnExchange(order, ReturnFlowType.exchange),
        onSupport: () => _openOrderSupport(order),
      ),
    );
  }

  void _openOrderSupport(CustomerOrder order) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SupportScreen(
        reference: SupportReference(orderNumber: order.orderNumber ?? order.id),
      ),
    );
  }

  void _openReturnExchange(CustomerOrder order, ReturnFlowType flowType) {
    _track(AppAnalyticsEvents.returnOpened);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) =>
          ReturnExchangeScreen(order: order, flowType: flowType),
    );
  }

  void _track(String name) =>
      ref.read(analyticsGatewayProvider).track(AnalyticsEvent(name: name));

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
        child: Semantics(
          label: 'Loading orders',
          liveRegion: true,
          child: AppSkeletonLoader(width: 240, height: 180),
        ),
      );
    }
    return Semantics(
      label: 'Order history',
      explicitChildNodes: true,
      child: RefreshIndicator(
        onRefresh: () => _load(refresh: true),
        child: ListView.builder(
          shrinkWrap: widget.embedded,
          physics: widget.embedded
              ? const NeverScrollableScrollPhysics()
              : null,
          itemCount: _orders.length + 3,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Orders', style: Theme.of(context).textTheme.titleLarge),
                  if (_offline)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: AppNetworkStatusBanner(
                        message: 'Offline. Showing last loaded orders.',
                        status: AppNetworkStatus.offline,
                      ),
                    ),
                  if (_error != null)
                    AppErrorState(
                      error: _error!,
                      onRetry: () => _load(refresh: true),
                    ),
                  if (_orders.isEmpty && _error == null)
                    const AppEmptyState(
                      title: 'No orders yet',
                      message: 'Orders from Shopify Customer Account will appear here.',
                      icon: Icons.receipt_long_outlined,
                    ),
                ],
              );
            }
            final orderIndex = index - 1;
            if (orderIndex < _orders.length) {
              return _OrderTile(
                order: _orders[orderIndex],
                onTap: () => _openOrder(_orders[orderIndex]),
              );
            }
            if (orderIndex == _orders.length &&
                (_pageInfo?.hasNextPage ?? false)) {
              return AppButton.secondary(
                label: _loadingMore ? 'Loading' : 'Load more',
                icon: Icons.expand_more,
                onPressed: _loadingMore ? null : _loadMore,
              );
            }
            return const SizedBox(height: AppSpacing.lg);
          },
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order, required this.onTap});
  final CustomerOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'Open order ${order.orderNumber ?? order.id}',
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(order.orderNumber ?? 'Order'),
      subtitle: Text(
        '${_date(order.processedAt)} / ${order.statusLabel} / ${order.itemCount} item${order.itemCount == 1 ? '' : 's'}',
      ),
      trailing: Text(_money(order.totalPrice)),
      onTap: onTap,
    ),
  );
}

class _OrderDetailsSheet extends StatelessWidget {
  const _OrderDetailsSheet({
    required this.order,
    required this.onTrack,
    required this.onReorder,
    required this.onReturn,
    required this.onExchange,
    required this.onSupport,
  });
  final CustomerOrder order;
  final VoidCallback onTrack;
  final VoidCallback onReorder;
  final VoidCallback onReturn;
  final VoidCallback onExchange;
  final VoidCallback onSupport;

  @override
  Widget build(BuildContext context) {
    final tracking = order.fulfillments
        .where((f) => f.hasTracking)
        .toList(growable: false);
    final returnEligibility = evaluateReturnEligibility(order);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            order.orderNumber ?? 'Order details',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          _row('Order date', _date(order.processedAt)),
          _row('Order status', order.statusLabel),
          _row('Payment status', order.paymentStatus ?? 'Not available'),
          _row(
            'Fulfillment status',
            order.fulfillmentStatus ?? 'Not available',
          ),
          const SizedBox(height: AppSpacing.md),
          for (final item in order.lineItems)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(item.title),
              subtitle: Text(
                '${item.variantTitle ?? 'Variant'} / Qty ${item.quantity}',
              ),
              trailing: Text(_money(item.price)),
            ),
          const SizedBox(height: AppSpacing.md),
          _row('Discount', _money(order.discountTotal)),
          _row('Shipping', _money(order.shippingPrice)),
          _row('Taxes', _money(order.taxTotal)),
          _row('Final total', _money(order.totalPrice)),
          _row('Shipping address', _address(order.shippingAddress)),
          _row('Billing address', _address(order.billingAddress)),
          if (tracking.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Tracking', style: Theme.of(context).textTheme.titleMedium),
            for (final fulfillment in tracking)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(fulfillment.trackingNumber ?? 'Tracking available'),
                subtitle: Text(
                  '${fulfillment.trackingCompany ?? 'Courier unavailable'} / ${fulfillment.status ?? 'Shipment status unavailable'}',
                ),
                onTap: onTrack,
              ),
          ],
          const SizedBox(height: AppSpacing.md),
          AppButton.secondary(
            label: 'Reorder',
            icon: Icons.replay,
            onPressed: onReorder,
          ),
          AppButton.text(
            label: 'Contact Support',
            icon: Icons.support_agent,
            onPressed: onSupport,
          ),
          if (returnEligibility.canReturn)
            AppButton.text(
              label: 'Return',
              icon: Icons.assignment_return_outlined,
              semanticLabel: 'Start return for order',
              onPressed: onReturn,
            ),
          if (returnEligibility.canExchange)
            AppButton.text(
              label: 'Exchange',
              icon: Icons.swap_horiz,
              semanticLabel: 'Start exchange for order',
              onPressed: onExchange,
            ),
          AppButton.text(
            label: 'Download Invoice',
            icon: Icons.download_outlined,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

Widget _row(String label, String value) => Padding(
  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
  child: Semantics(
    label: '$label: $value',
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 132, child: Text(label)),
        Expanded(child: Text(value)),
      ],
    ),
  ),
);
String _money(Money? money) =>
    money == null ? 'Not available' : '${money.currencyCode} ${money.amount}';
String _date(DateTime? value) => value == null
    ? 'Not available'
    : value.toLocal().toString().split('.').first;
String _address(CustomerAddress? address) => address == null
    ? 'Not available'
    : [
        address.address1,
        address.address2,
        address.city,
        address.province,
        address.country,
        address.zip,
      ].whereType<String>().where((part) => part.trim().isNotEmpty).join(', ');
