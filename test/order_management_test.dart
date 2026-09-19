import 'package:flexwolf/features/account/domain/customer_order.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CustomerOrder parses dynamic Shopify status and totals', () {
    final order = CustomerOrder.fromShopify({
      'id': 'gid://shopify/Order/1',
      'name': '#1001',
      'processedAt': '2026-09-01T10:00:00Z',
      'financialStatus': 'PAID',
      'fulfillmentStatus': 'SHIPPED',
      'displayFulfillmentStatus': 'Out for delivery',
      'totalPrice': {'amount': '120.00', 'currencyCode': 'USD'},
      'totalTax': {'amount': '8.00', 'currencyCode': 'USD'},
      'lineItems': {
        'nodes': [
          {
            'title': 'Flex Tee',
            'quantity': 2,
            'variantTitle': 'Black / M',
            'discountedTotalPrice': {'amount': '60.00', 'currencyCode': 'USD'},
          },
        ],
      },
      'fulfillments': [
        {
          'status': 'IN_TRANSIT',
          'trackingCompany': 'UPS',
          'trackingNumber': '1Z',
          'trackingUrl': 'https://track.example/1Z',
        },
      ],
    });

    expect(order.orderNumber, '#1001');
    expect(order.paymentStatus, 'PAID');
    expect(order.statusLabel, 'Out for delivery');
    expect(order.itemCount, 2);
    expect(order.totalPrice?.amount.toString(), '120.00');
    expect(order.taxTotal?.amount.toString(), '8.00');
    expect(order.fulfillments.single.hasTracking, isTrue);
  });

  test('orders can be sorted newest first without hardcoded statuses', () {
    final older = CustomerOrder(
      id: '1',
      processedAt: DateTime.utc(2026, 8, 1),
      fulfillmentStatus: 'RETURNED',
    );
    final newer = CustomerOrder(
      id: '2',
      processedAt: DateTime.utc(2026, 9, 1),
      fulfillmentStatus: 'CUSTOM_SHOPIFY_STATUS',
    );
    final orders = [older, newer]
      ..sort((a, b) => b.processedAt!.compareTo(a.processedAt!));

    expect(orders.first.id, '2');
    expect(orders.first.statusLabel, 'CUSTOM_SHOPIFY_STATUS');
  });
}
