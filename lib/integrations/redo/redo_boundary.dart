import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/features/returns/domain/return_exchange_models.dart';

abstract interface class RedoReturnsGateway {
  Future<List<ReturnReason>> fetchReasons();
  Future<List<ReturnExchangeRecord>> fetchHistory({String? orderId});
  Future<ReturnExchangeRecord> submit(ReturnExchangeRequest request);
}

class ClientDependencyRedoReturnsGateway implements RedoReturnsGateway {
  const ClientDependencyRedoReturnsGateway();

  AppException get _pending => const AppException(
    kind: AppErrorKind.unavailable,
    message: 'CLIENT DEPENDENCY: Redo returns credentials and API contract are not configured.',
    code: 'redo_returns_not_configured',
    isRetryable: true,
  );

  @override
  Future<List<ReturnReason>> fetchReasons() => throw _pending;

  @override
  Future<List<ReturnExchangeRecord>> fetchHistory({String? orderId}) =>
      throw _pending;

  @override
  Future<ReturnExchangeRecord> submit(ReturnExchangeRequest request) {
    request.validate();
    throw _pending;
  }
}
