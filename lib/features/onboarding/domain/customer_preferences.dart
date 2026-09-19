import 'dart:convert';

import 'package:flutter/foundation.dart';

@immutable
class CustomerPreferences {
  const CustomerPreferences({
    this.categoryIds = const <String>[],
    this.sizeIds = const <String>[],
  });

  final List<String> categoryIds;
  final List<String> sizeIds;

  bool get hasSelections => categoryIds.isNotEmpty || sizeIds.isNotEmpty;

  CustomerPreferences copyWith({
    List<String>? categoryIds,
    List<String>? sizeIds,
  }) {
    return CustomerPreferences(
      categoryIds: categoryIds ?? this.categoryIds,
      sizeIds: sizeIds ?? this.sizeIds,
    );
  }

  Map<String, Object> toJson() => <String, Object>{
    'categoryIds': categoryIds,
    'sizeIds': sizeIds,
  };

  static CustomerPreferences fromJsonString(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map<String, Object?>) {
      return const CustomerPreferences();
    }

    return CustomerPreferences(
      categoryIds: _readStringList(decoded['categoryIds']),
      sizeIds: _readStringList(decoded['sizeIds']),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  static List<String> _readStringList(Object? value) {
    if (value is! List) {
      return const <String>[];
    }
    return value.whereType<String>().toList(growable: false);
  }
}
