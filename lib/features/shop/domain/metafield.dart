class ShopifyMetafield {
  const ShopifyMetafield({
    required this.namespace,
    required this.key,
    required this.type,
    this.value,
  });

  factory ShopifyMetafield.fromShopify(Map<String, Object?> json) {
    final namespace = json['namespace'];
    final key = json['key'];
    final type = json['type'];
    if (namespace is! String || key is! String || type is! String) {
      throw const FormatException('Invalid Shopify metafield payload.');
    }

    return ShopifyMetafield(
      namespace: namespace,
      key: key,
      type: type,
      value: json['value'] as String?,
    );
  }

  final String namespace;
  final String key;
  final String type;
  final String? value;
}

class MetafieldDefinitionRef {
  const MetafieldDefinitionRef({
    required this.ownerType,
    required this.namespace,
    required this.key,
  });

  final String ownerType;
  final String namespace;
  final String key;
}

class MetafieldRegistry {
  const MetafieldRegistry(this.definitions);

  final List<MetafieldDefinitionRef> definitions;

  MetafieldDefinitionRef? find(String ownerType, String namespace, String key) {
    for (final definition in definitions) {
      if (definition.ownerType == ownerType &&
          definition.namespace == namespace &&
          definition.key == key) {
        return definition;
      }
    }
    return null;
  }
}
