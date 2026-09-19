import 'package:flexwolf/features/account/domain/customer_order.dart';
import 'package:flexwolf/features/returns/domain/return_exchange_models.dart';

abstract interface class ReturnsRepository {
  Future<ReturnEligibility> eligibilityFor(CustomerOrder order);
  Future<List<ReturnReason>> fetchReasons();
  Future<List<ReturnExchangeRecord>> fetchHistory({String? orderId});
  Future<ReturnExchangeRecord> submit(ReturnExchangeRequest request);
}
