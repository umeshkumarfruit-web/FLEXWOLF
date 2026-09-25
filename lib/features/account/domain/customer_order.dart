import 'package:flexwolf/features/account/domain/customer.dart';
import 'package:flexwolf/features/shop/domain/money.dart';
import 'package:flexwolf/features/shop/domain/product_media.dart';

class CustomerOrder {
  const CustomerOrder({
    required this.id,
    this.orderNumber,
    this.processedAt,
    this.totalPrice,
    this.subtotalPrice,
    this.discountTotal,
    this.shippingPrice,
    this.taxTotal,
    this.paymentStatus,
    this.fulfillmentStatus,
    this.displayStatus,
    this.shippingAddress,
    this.billingAddress,
    this.lineItems = const <CustomerOrderLineItem>[],
    this.fulfillments = const <CustomerFulfillment>[],
  });

  factory CustomerOrder.fromShopify(Map<String, Object?> json) {
    final id = json['id'];
    if (id is! String) {
      throw const FormatException('Customer order is missing id.');
    }

    return CustomerOrder(
      id: id,
      orderNumber: json['name'] as String? ?? json['orderNumber']?.toString(),
      processedAt: DateTime.tryParse(json['processedAt'] as String? ?? ''),
      totalPrice: _money(json['totalPrice'] ?? json['totalPriceSet']),
      subtotalPrice: _money(
        json['subtotalPrice'] ?? json['subtotal'] ?? json['subtotalPriceSet'],
      ),
      discountTotal: _money(
        json['totalDiscounts'] ?? json['totalDiscountsSet'],
      ),
      shippingPrice: _money(
        json['totalShippingPrice'] ??
            json['totalShipping'] ??
            json['totalShippingPriceSet'],
      ),
      taxTotal: _money(json['totalTax'] ?? json['totalTaxSet']),
      paymentStatus:
          json['financialStatus'] as String? ??
          json['paymentStatus'] as String?,
      fulfillmentStatus: json['fulfillmentStatus'] as String?,
      displayStatus:
          json['displayFulfillmentStatus'] as String? ??
          json['displayFinancialStatus'] as String?,
      shippingAddress: json['shippingAddress'] is Map<String, Object?>
          ? CustomerAddress.fromShopify(
              json['shippingAddress']! as Map<String, Object?>,
            )
          : null,
      billingAddress: json['billingAddress'] is Map<String, Object?>
          ? CustomerAddress.fromShopify(
              json['billingAddress']! as Map<String, Object?>,
            )
          : null,
      lineItems: _connectionNodes(json['lineItems'])
          .map(CustomerOrderLineItem.fromShopify)
          .toList(growable: false),
      fulfillments: _connectionOrListMaps(json['fulfillments'])
          .map(CustomerFulfillment.fromShopify)
          .toList(growable: false),
    );
  }

  final String id;
  final String? orderNumber;
  final DateTime? processedAt;
  final Money? totalPrice;
  final Money? subtotalPrice;
  final Money? discountTotal;
  final Money? shippingPrice;
  final Money? taxTotal;
  final String? paymentStatus;
  final String? fulfillmentStatus;
  final String? displayStatus;
  final CustomerAddress? shippingAddress;
  final CustomerAddress? billingAddress;
  final List<CustomerOrderLineItem> lineItems;
  final List<CustomerFulfillment> fulfillments;

  int get itemCount =>
      lineItems.fold<int>(0, (total, item) => total + item.quantity);
  String get statusLabel =>
      displayStatus ??
      fulfillmentStatus ??
      paymentStatus ??
      'Status unavailable';
}

class CustomerOrderLineItem {
  const CustomerOrderLineItem({
    required this.title,
    required this.quantity,
    this.variantTitle,
    this.sku,
    this.price,
    this.discount,
    this.image,
    this.selectedOptions = const <String, String>{},
  });

  factory CustomerOrderLineItem.fromShopify(Map<String, Object?> json) {
    final title = json['name'] ?? json['title'];
    final quantity = json['quantity'];
    if (title is! String || quantity is! int) {
      throw const FormatException('Customer order line item is invalid.');
    }

    return CustomerOrderLineItem(
      title: title,
      quantity: quantity,
      variantTitle: json['variantTitle'] as String?,
      sku: json['sku'] as String?,
      price: _money(
        json['price'] ??
            json['totalPrice'] ??
            json['discountedTotalPrice'] ??
            json['originalTotalPrice'],
      ),
      discount: _money(json['discountedTotalPrice']),
      image: json['image'] is Map<String, Object?>
          ? ProductImage.fromShopify(json['image']! as Map<String, Object?>)
          : null,
      selectedOptions: _selectedOptions(
        json['selectedOptions'] ?? json['variantOptions'],
      ),
    );
  }

  final String title;
  final int quantity;
  final String? variantTitle;
  final String? sku;
  final Money? price;
  final Money? discount;
  final ProductImage? image;
  final Map<String, String> selectedOptions;

  String? get size => selectedOptions['Size'] ?? selectedOptions['size'];
  String? get color => selectedOptions['Color'] ?? selectedOptions['color'];
}

class CustomerFulfillment {
  const CustomerFulfillment({
    this.status,
    this.trackingCompany,
    this.trackingNumber,
    this.trackingUrl,
  });

  factory CustomerFulfillment.fromShopify(Map<String, Object?> json) {
    final tracking = json['trackingInformation'];
    final firstTracking = tracking is List && tracking.isNotEmpty
        ? tracking.first
        : null;
    final trackingMap = firstTracking is Map<String, Object?>
        ? firstTracking
        : null;
    return CustomerFulfillment(
      status: json['status'] as String?,
      trackingCompany:
          trackingMap?['company'] as String? ??
          json['trackingCompany'] as String?,
      trackingNumber:
          trackingMap?['number'] as String? ??
          json['trackingNumber'] as String?,
      trackingUrl: (trackingMap?['url'] ?? json['trackingUrl']) == null
          ? null
          : Uri.tryParse(
              (trackingMap?['url'] ?? json['trackingUrl']).toString(),
            ),
    );
  }

  final String? status;
  final String? trackingCompany;
  final String? trackingNumber;
  final Uri? trackingUrl;

  bool get hasTracking =>
      trackingNumber != null || trackingCompany != null || trackingUrl != null;
}

Money? _money(Object? value) {
  if (value is Map<String, Object?>) {
    final presentment = value['presentmentMoney'];
    final shopMoney = value['shopMoney'];
    if (presentment is Map<String, Object?>) {
      return Money.fromShopify(presentment);
    }
    if (shopMoney is Map<String, Object?>) {
      return Money.fromShopify(shopMoney);
    }
    if (value['amount'] is String) {
      return Money.fromShopify(value);
    }
  }
  return null;
}

List<Map<String, Object?>> _connectionNodes(Object? value) {
  if (value is! Map<String, Object?>) {
    return const <Map<String, Object?>>[];
  }
  final nodes = value['nodes'];
  if (nodes is List) {
    return nodes.whereType<Map<String, Object?>>().toList(growable: false);
  }
  return const <Map<String, Object?>>[];
}

List<Map<String, Object?>> _connectionOrListMaps(Object? value) {
  if (value is Map<String, Object?>) return _connectionNodes(value);
  if (value is! List) return const <Map<String, Object?>>[];
  return value.whereType<Map<String, Object?>>().toList(growable: false);
}

Map<String, String> _selectedOptions(Object? value) {
  if (value is! List) return const <String, String>{};
  return <String, String>{
    for (final option in value.whereType<Map<String, Object?>>())
      if (option['name'] is String && option['value'] is String)
        option['name']! as String: option['value']! as String,
  };
}
