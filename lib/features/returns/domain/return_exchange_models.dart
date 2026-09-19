import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/features/account/domain/customer_order.dart';

enum ReturnFlowType { returnOnly, exchange }

enum ReturnExchangeStatus {
  requested,
  confirmed,
  processing,
  completed,
  rejected,
}

class ReturnReason {
  const ReturnReason({required this.id, required this.label});

  final String id;
  final String label;
}

class ReturnEligibility {
  const ReturnEligibility({
    required this.orderId,
    required this.canReturn,
    required this.canExchange,
    this.reason,
  });

  final String orderId;
  final bool canReturn;
  final bool canExchange;
  final String? reason;
}

class ReturnExchangeRequest {
  const ReturnExchangeRequest({
    required this.orderId,
    required this.lineItemTitle,
    required this.quantity,
    required this.reasonId,
    required this.flowType,
    this.exchangeSize,
    this.exchangeColor,
    this.note,
  });

  final String orderId;
  final String lineItemTitle;
  final int quantity;
  final String reasonId;
  final ReturnFlowType flowType;
  final String? exchangeSize;
  final String? exchangeColor;
  final String? note;

  void validate() {
    if (orderId.trim().isEmpty) {
      throw const AppException(
        kind: AppErrorKind.validation,
        message: 'Order is required.',
        code: 'return_order_required',
      );
    }
    if (lineItemTitle.trim().isEmpty || quantity <= 0) {
      throw const AppException(
        kind: AppErrorKind.validation,
        message: 'Select an item to continue.',
        code: 'return_item_required',
      );
    }
    if (reasonId.trim().isEmpty) {
      throw const AppException(
        kind: AppErrorKind.validation,
        message: 'Select a return reason.',
        code: 'return_reason_required',
      );
    }
    if (flowType == ReturnFlowType.exchange &&
        (exchangeSize?.trim().isEmpty ?? true) &&
        (exchangeColor?.trim().isEmpty ?? true)) {
      throw const AppException(
        kind: AppErrorKind.validation,
        message: 'Choose a size or color for the exchange.',
        code: 'exchange_option_required',
      );
    }
  }
}

class ReturnExchangeRecord {
  const ReturnExchangeRecord({
    required this.id,
    required this.orderId,
    required this.flowType,
    required this.status,
    required this.createdAt,
    required this.reasonLabel,
    required this.lineItemTitle,
  });

  final String id;
  final String orderId;
  final ReturnFlowType flowType;
  final ReturnExchangeStatus status;
  final DateTime createdAt;
  final String reasonLabel;
  final String lineItemTitle;
}

ReturnEligibility evaluateReturnEligibility(CustomerOrder order) {
  final status = '${order.fulfillmentStatus ?? ''} ${order.displayStatus ?? ''}'
      .toLowerCase();
  final paid = (order.paymentStatus ?? '').toLowerCase();
  final hasItems = order.lineItems.any((item) => item.quantity > 0);
  final blockedFulfillment = status.contains('unfulfilled');
  final fulfilled =
      !blockedFulfillment &&
      (status.contains('fulfilled') ||
          status.contains('delivered') ||
          order.fulfillments.isNotEmpty);
  final paymentOk =
      paid.isEmpty || paid.contains('paid') || paid.contains('authorized');

  if (!hasItems) {
    return ReturnEligibility(
      orderId: order.id,
      canReturn: false,
      canExchange: false,
      reason: 'No returnable items are available.',
    );
  }
  if (!fulfilled) {
    return ReturnEligibility(
      orderId: order.id,
      canReturn: false,
      canExchange: false,
      reason: 'Returns open after fulfillment.',
    );
  }
  if (!paymentOk) {
    return ReturnEligibility(
      orderId: order.id,
      canReturn: false,
      canExchange: false,
      reason: 'Payment status is not eligible.',
    );
  }
  return ReturnEligibility(
    orderId: order.id,
    canReturn: true,
    canExchange: true,
  );
}
