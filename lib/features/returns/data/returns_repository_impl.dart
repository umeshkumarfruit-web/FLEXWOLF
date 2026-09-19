// ignore_for_file: prefer_initializing_formals

import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/features/account/domain/customer_order.dart';
import 'package:flexwolf/features/returns/domain/return_exchange_models.dart';
import 'package:flexwolf/features/returns/domain/returns_repository.dart';
import 'package:flexwolf/integrations/redo/redo_boundary.dart';

class DefaultReturnsRepository implements ReturnsRepository {
  DefaultReturnsRepository({
    required RedoReturnsGateway redo,
    required List<ReturnReason> configuredReasons,
  }) : _redo = redo,
       _configuredReasons = configuredReasons;

  final RedoReturnsGateway _redo;
  final List<ReturnReason> _configuredReasons;
  final Map<String, ReturnEligibility> _eligibilityCache = {};
  final Map<String, List<ReturnExchangeRecord>> _historyCache = {};
  final Set<String> _submittingKeys = {};

  @override
  Future<ReturnEligibility> eligibilityFor(CustomerOrder order) async {
    return _eligibilityCache.putIfAbsent(
      order.id,
      () => evaluateReturnEligibility(order),
    );
  }

  @override
  Future<List<ReturnReason>> fetchReasons() async {
    try {
      final redoReasons = await _redo.fetchReasons();
      if (redoReasons.isNotEmpty) return redoReasons;
    } on AppException catch (error) {
      if (error.code != 'redo_returns_not_configured') rethrow;
    }
    return _configuredReasons;
  }

  @override
  Future<List<ReturnExchangeRecord>> fetchHistory({String? orderId}) async {
    final cacheKey = orderId ?? '_all';
    final cached = _historyCache[cacheKey];
    if (cached != null) return cached;
    try {
      final history = await _redo.fetchHistory(orderId: orderId);
      _historyCache[cacheKey] = history;
      return history;
    } on AppException catch (error) {
      if (error.code != 'redo_returns_not_configured') rethrow;
      return const <ReturnExchangeRecord>[];
    }
  }

  @override
  Future<ReturnExchangeRecord> submit(ReturnExchangeRequest request) async {
    request.validate();
    final key = [
      request.orderId,
      request.lineItemTitle,
      request.flowType.name,
      request.reasonId,
      request.exchangeSize ?? '',
      request.exchangeColor ?? '',
    ].join('|');
    if (!_submittingKeys.add(key)) {
      throw const AppException(
        kind: AppErrorKind.validation,
        message: 'This request is already being submitted.',
        code: 'return_duplicate_submit',
      );
    }
    try {
      final record = await _redo.submit(request);
      _historyCache.remove(request.orderId);
      _historyCache.remove('_all');
      return record;
    } finally {
      _submittingKeys.remove(key);
    }
  }
}
