import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/features/account/domain/customer_order.dart';
import 'package:flexwolf/features/returns/data/returns_repository_impl.dart';
import 'package:flexwolf/features/returns/domain/return_exchange_models.dart';
import 'package:flexwolf/integrations/redo/redo_boundary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fulfilled paid orders are return and exchange eligible', () async {
    final eligibility = evaluateReturnEligibility(_order());

    expect(eligibility.canReturn, isTrue);
    expect(eligibility.canExchange, isTrue);
  });

  test('unfulfilled orders hide return and exchange actions', () {
    final eligibility = evaluateReturnEligibility(
      _order(fulfillmentStatus: 'UNFULFILLED', fulfillments: const []),
    );

    expect(eligibility.canReturn, isFalse);
    expect(eligibility.canExchange, isFalse);
    expect(eligibility.reason, isNotEmpty);
  });

  test(
    'configured reasons are used when Redo credentials are unavailable',
    () async {
      final repository = DefaultReturnsRepository(
        redo: const ClientDependencyRedoReturnsGateway(),
        configuredReasons: const [ReturnReason(id: 'fit', label: 'Fit Issue')],
      );

      final reasons = await repository.fetchReasons();

      expect(reasons.single.id, 'fit');
    },
  );

  test('history falls back to empty until Redo is configured', () async {
    final repository = DefaultReturnsRepository(
      redo: const ClientDependencyRedoReturnsGateway(),
      configuredReasons: const [],
    );

    await expectLater(
      repository.fetchHistory(orderId: 'order-1'),
      completion(isEmpty),
    );
  });

  test('exchange request requires size or color', () {
    const request = ReturnExchangeRequest(
      orderId: 'order-1',
      lineItemTitle: 'FLEXWOLF Tee',
      quantity: 1,
      reasonId: 'wrong_size',
      flowType: ReturnFlowType.exchange,
    );

    expect(request.validate, throwsA(isA<AppException>()));
  });
}

CustomerOrder _order({
  String fulfillmentStatus = 'FULFILLED',
  List<CustomerFulfillment> fulfillments = const [
    CustomerFulfillment(status: 'SUCCESS'),
  ],
}) {
  return CustomerOrder(
    id: 'order-1',
    orderNumber: '#1001',
    paymentStatus: 'PAID',
    fulfillmentStatus: fulfillmentStatus,
    lineItems: const [
      CustomerOrderLineItem(title: 'FLEXWOLF Tee', quantity: 1),
    ],
    fulfillments: fulfillments,
  );
}
