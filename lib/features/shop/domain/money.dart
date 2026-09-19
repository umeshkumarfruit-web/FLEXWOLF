class Money {
  const Money({required this.amount, required this.currencyCode});

  factory Money.fromShopify(Map<String, Object?> json) {
    final amount = json['amount'];
    final currencyCode = json['currencyCode'];
    if (amount is! String || currencyCode is! String) {
      throw const FormatException('Invalid Shopify MoneyV2 payload.');
    }

    return Money(
      amount: DecimalAmount.parse(amount),
      currencyCode: currencyCode,
    );
  }

  final DecimalAmount amount;
  final String currencyCode;
}

bool isDiscountedPrice(Money price, Money? compareAtPrice) {
  if (compareAtPrice == null ||
      compareAtPrice.currencyCode != price.currencyCode) {
    return false;
  }
  final current = num.tryParse(price.amount.value);
  final regular = num.tryParse(compareAtPrice.amount.value);
  return current != null && regular != null && regular > current;
}

class DecimalAmount {
  const DecimalAmount._(this.value);

  factory DecimalAmount.parse(String input) {
    final normalized = input.trim();
    if (!RegExp(r'^-?\d+(\.\d+)?$').hasMatch(normalized)) {
      throw FormatException('Invalid decimal amount: $input');
    }
    return DecimalAmount._(normalized);
  }

  final String value;

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      other is DecimalAmount && other.value == value;

  @override
  int get hashCode => value.hashCode;
}
