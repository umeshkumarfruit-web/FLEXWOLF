import 'package:flexwolf/features/shop/domain/money.dart';
import 'package:flexwolf/features/shop/domain/product_media.dart';

class ProductVariant {
  const ProductVariant({
    required this.id,
    required this.availableForSale,
    required this.price,
    this.title,
    this.sku,
    this.compareAtPrice,
    this.image,
    this.selectedOptions = const <SelectedOption>[],
    this.quantityAvailable,
    this.currentlyNotInStock,
  });

  factory ProductVariant.fromShopify(Map<String, Object?> json) {
    final id = json['id'];
    final availableForSale = json['availableForSale'];
    final price = json['price'];
    if (id is! String ||
        availableForSale is! bool ||
        price is! Map<String, Object?>) {
      throw const FormatException('Invalid Shopify variant payload.');
    }

    return ProductVariant(
      id: id,
      title: json['title'] as String?,
      sku: json['sku'] as String?,
      availableForSale: availableForSale,
      quantityAvailable: json['quantityAvailable'] as int?,
      currentlyNotInStock: json['currentlyNotInStock'] as bool?,
      price: Money.fromShopify(price),
      compareAtPrice: json['compareAtPrice'] is Map<String, Object?>
          ? Money.fromShopify(json['compareAtPrice']! as Map<String, Object?>)
          : null,
      image: json['image'] is Map<String, Object?>
          ? ProductImage.fromShopify(json['image']! as Map<String, Object?>)
          : null,
      selectedOptions: _selectedOptions(json['selectedOptions']),
    );
  }

  final String id;
  final String? title;
  final String? sku;
  final bool availableForSale;
  final int? quantityAvailable;
  final bool? currentlyNotInStock;
  final Money price;
  final Money? compareAtPrice;
  final ProductImage? image;
  final List<SelectedOption> selectedOptions;

  String? get color => selectedOptionValue('color');
  String? get size => selectedOptionValue('size');

  String? selectedOptionValue(String name) {
    for (final option in selectedOptions) {
      if (option.name.toLowerCase() == name.toLowerCase()) {
        return option.value;
      }
    }
    return null;
  }
}

class SelectedOption {
  const SelectedOption({required this.name, required this.value});

  factory SelectedOption.fromShopify(Map<String, Object?> json) {
    final name = json['name'];
    final value = json['value'];
    if (name is! String || value is! String) {
      throw const FormatException('Invalid selected option payload.');
    }
    return SelectedOption(name: name, value: value);
  }

  final String name;
  final String value;
}

class ProductOption {
  const ProductOption({
    required this.id,
    required this.name,
    required this.values,
  });

  factory ProductOption.fromShopify(Map<String, Object?> json) {
    final id = json['id'];
    final name = json['name'];
    final values = json['values'];
    if (id is! String || name is! String || values is! List) {
      throw const FormatException('Invalid product option payload.');
    }
    return ProductOption(
      id: id,
      name: name,
      values: values.whereType<String>().toList(growable: false),
    );
  }

  final String id;
  final String name;
  final List<String> values;
}

List<SelectedOption> _selectedOptions(Object? value) {
  if (value is! List) {
    return const <SelectedOption>[];
  }
  return value
      .whereType<Map<String, Object?>>()
      .map(SelectedOption.fromShopify)
      .toList(growable: false);
}
