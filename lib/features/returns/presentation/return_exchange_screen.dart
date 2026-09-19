import 'package:flexwolf/core/connectivity/connectivity_service.dart';
import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/services/service_registry.dart';
import 'package:flexwolf/core/widgets/app_button.dart';
import 'package:flexwolf/core/widgets/app_empty_state.dart';
import 'package:flexwolf/core/widgets/app_error_state.dart';
import 'package:flexwolf/core/widgets/app_form_field.dart';
import 'package:flexwolf/core/widgets/app_loading_indicator.dart';
import 'package:flexwolf/core/widgets/app_network_status_banner.dart';
import 'package:flexwolf/features/account/domain/customer_order.dart';
import 'package:flexwolf/features/returns/data/returns_providers.dart';
import 'package:flexwolf/features/returns/domain/return_exchange_models.dart';
import 'package:flexwolf/integrations/analytics/analytics_boundary.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReturnExchangeScreen extends ConsumerStatefulWidget {
  const ReturnExchangeScreen({
    required this.order,
    required this.flowType,
    super.key,
  });

  final CustomerOrder order;
  final ReturnFlowType flowType;

  @override
  ConsumerState<ReturnExchangeScreen> createState() =>
      _ReturnExchangeScreenState();
}

class _ReturnExchangeScreenState extends ConsumerState<ReturnExchangeScreen> {
  final _noteController = TextEditingController();
  final _sizeController = TextEditingController();
  final _colorController = TextEditingController();
  List<ReturnReason> _reasons = const <ReturnReason>[];
  List<ReturnExchangeRecord> _history = const <ReturnExchangeRecord>[];
  ReturnEligibility? _eligibility;
  ReturnReason? _reason;
  CustomerOrderLineItem? _item;
  bool _loading = true;
  bool _submitting = false;
  bool _offline = false;
  AppException? _error;
  ReturnExchangeRecord? _confirmation;

  bool get _isExchange => widget.flowType == ReturnFlowType.exchange;

  @override
  void initState() {
    super.initState();
    _item = widget.order.lineItems.isEmpty
        ? null
        : widget.order.lineItems.first;
    _sizeController.text = _item?.size ?? '';
    _colorController.text = _item?.color ?? '';
    _load(trackStarted: true);
  }

  @override
  void dispose() {
    _noteController.dispose();
    _sizeController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _load({bool trackStarted = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final connectivity = await ref
          .read(connectivityServiceProvider)
          .current();
      _offline = connectivity.quality == ConnectivityQuality.offline;
      if (_offline) {
        throw const AppException(
          kind: AppErrorKind.network,
          message: 'Returns cannot refresh while offline.',
          code: 'returns_offline',
          isRetryable: true,
        );
      }
      final repository = ref.read(returnsRepositoryProvider);
      _eligibility = await repository.eligibilityFor(widget.order);
      _reasons = await repository.fetchReasons();
      _history = await repository.fetchHistory(orderId: widget.order.id);
      if (_reason == null && _reasons.isNotEmpty) _reason = _reasons.first;
      if (trackStarted) {
        _track(
          _isExchange
              ? AppAnalyticsEvents.exchangeStarted
              : AppAnalyticsEvents.returnStarted,
        );
      }
    } catch (error) {
      _error = error is AppException ? error : mapUnknownException(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    if (_item == null || _reason == null || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final request = ReturnExchangeRequest(
        orderId: widget.order.id,
        lineItemTitle: _item!.title,
        quantity: _item!.quantity,
        reasonId: _reason!.id,
        flowType: widget.flowType,
        exchangeSize: _isExchange ? _sizeController.text : null,
        exchangeColor: _isExchange ? _colorController.text : null,
        note: _noteController.text,
      );
      final record = await ref.read(returnsRepositoryProvider).submit(request);
      _confirmation = record;
      _history = await ref
          .read(returnsRepositoryProvider)
          .fetchHistory(orderId: widget.order.id);
      _track(
        _isExchange
            ? AppAnalyticsEvents.exchangeSubmitted
            : AppAnalyticsEvents.returnSubmitted,
      );
      // ignore: deprecated_member_use
      SemanticsService.announce('Request submitted', TextDirection.ltr);
    } catch (error) {
      _error = error is AppException ? error : mapUnknownException(error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _track(String name) =>
      ref.read(analyticsGatewayProvider).track(AnalyticsEvent(name: name));

  @override
  Widget build(BuildContext context) {
    final title = _isExchange ? 'Exchange request' : 'Return request';
    if (_loading) {
      return Semantics(
        label: 'Loading $title',
        liveRegion: true,
        child: const Center(child: AppSkeletonLoader(width: 260, height: 220)),
      );
    }
    final eligibility = _eligibility;
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            if (_offline)
              const AppNetworkStatusBanner(
                message: 'Offline. Connect to submit a request.',
                status: AppNetworkStatus.offline,
              ),
            if (_error != null)
              AppErrorState(error: _error!, onRetry: () => _load()),
            if (eligibility == null)
              const AppEmptyState(
                title: 'Eligibility unavailable',
                message: 'Try again to check this order.',
                icon: Icons.assignment_return_outlined,
              )
            else if (_isExchange
                ? !eligibility.canExchange
                : !eligibility.canReturn)
              AppEmptyState(
                title: _isExchange
                    ? 'Exchange unavailable'
                    : 'Return unavailable',
                message: eligibility.reason,
                icon: Icons.block_outlined,
              )
            else ...[
              _OrderSummary(order: widget.order, status: eligibility),
              const SizedBox(height: AppSpacing.md),
              _buildItemPicker(),
              const SizedBox(height: AppSpacing.md),
              _buildReasonPicker(),
              if (_isExchange) ...[
                const SizedBox(height: AppSpacing.md),
                AppFormField(controller: _sizeController, label: 'New size'),
                const SizedBox(height: AppSpacing.sm),
                AppFormField(controller: _colorController, label: 'New color'),
              ],
              const SizedBox(height: AppSpacing.md),
              AppFormField(controller: _noteController, label: 'Note'),
              const SizedBox(height: AppSpacing.md),
              AppButton.primary(
                label: _submitting ? 'Submitting' : 'Submit',
                icon: Icons.check_circle_outline,
                semanticLabel: 'Submit $title',
                onPressed: _submitting || _offline ? null : _submit,
              ),
              if (_confirmation != null) ...[
                const SizedBox(height: AppSpacing.md),
                _Confirmation(record: _confirmation!),
              ],
              const SizedBox(height: AppSpacing.lg),
              _History(records: _history),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemPicker() => DropdownButtonFormField<CustomerOrderLineItem>(
    initialValue: _item,
    decoration: const InputDecoration(labelText: 'Item'),
    items: [
      for (final item in widget.order.lineItems)
        DropdownMenuItem<CustomerOrderLineItem>(
          value: item,
          child: Text(item.title, overflow: TextOverflow.ellipsis),
        ),
    ],
    onChanged: (item) => setState(() => _item = item),
  );

  Widget _buildReasonPicker() => DropdownButtonFormField<ReturnReason>(
    initialValue: _reason,
    decoration: const InputDecoration(labelText: 'Reason'),
    items: [
      for (final reason in _reasons)
        DropdownMenuItem<ReturnReason>(
          value: reason,
          child: Text(reason.label, overflow: TextOverflow.ellipsis),
        ),
    ],
    onChanged: (reason) => setState(() => _reason = reason),
  );
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.order, required this.status});

  final CustomerOrder order;
  final ReturnEligibility status;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Order ${order.orderNumber ?? order.id} is eligible',
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.receipt_long_outlined),
      title: Text(order.orderNumber ?? 'Order'),
      subtitle: Text(status.reason ?? 'Eligible for return or exchange'),
    ),
  );
}

class _Confirmation extends StatelessWidget {
  const _Confirmation({required this.record});

  final ReturnExchangeRecord record;

  @override
  Widget build(BuildContext context) => AppEmptyState(
    title: record.flowType == ReturnFlowType.exchange
        ? 'Exchange confirmed'
        : 'Return confirmed',
    message: 'Status: ${record.status.name}',
    icon: Icons.task_alt,
  );
}

class _History extends StatelessWidget {
  const _History({required this.records});

  final List<ReturnExchangeRecord> records;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return const AppEmptyState(
        title: 'No return history',
        message: 'Submitted return and exchange requests will appear here.',
        icon: Icons.history,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('History', style: Theme.of(context).textTheme.titleMedium),
        for (final record in records)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              record.flowType == ReturnFlowType.exchange
                  ? Icons.swap_horiz
                  : Icons.assignment_return_outlined,
            ),
            title: Text(record.lineItemTitle),
            subtitle: Text('${record.reasonLabel} / ${record.status.name}'),
          ),
      ],
    );
  }
}
