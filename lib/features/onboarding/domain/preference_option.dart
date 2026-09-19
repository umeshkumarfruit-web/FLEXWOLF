import 'package:flutter/foundation.dart';

@immutable
class PreferenceOption {
  const PreferenceOption({required this.id, required this.label});

  final String id;
  final String label;
}

@immutable
class PreferenceCatalog {
  const PreferenceCatalog({required this.categories, required this.sizes});

  final List<PreferenceOption> categories;
  final List<PreferenceOption> sizes;
}

abstract final class FlexwolfPreferenceCatalog {
  static const catalog = PreferenceCatalog(
    categories: [
      PreferenceOption(id: 'tees', label: 'Tees'),
      PreferenceOption(id: 'tanks', label: 'Tanks'),
      PreferenceOption(id: 'shorts', label: 'Shorts'),
      PreferenceOption(id: 'sweats', label: 'Sweats'),
      PreferenceOption(id: 'new_drops', label: 'New Drops'),
    ],
    sizes: [
      PreferenceOption(id: 's', label: 'S'),
      PreferenceOption(id: 'm', label: 'M'),
      PreferenceOption(id: 'l', label: 'L'),
      PreferenceOption(id: 'xl', label: 'XL'),
      PreferenceOption(id: 'xxl', label: 'XXL'),
    ],
  );
}
