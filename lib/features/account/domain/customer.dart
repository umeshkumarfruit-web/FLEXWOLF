class CustomerProfile {
  const CustomerProfile({
    required this.id,
    this.displayName,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.defaultAddress,
    this.defaultBillingAddress,
    this.accountStatus = CustomerAccountStatus.active,
    this.marketingPreferences,
  });

  factory CustomerProfile.fromShopify(Map<String, Object?> json) {
    final id = json['id'];
    if (id is! String) {
      throw const FormatException('Customer profile is missing Shopify id.');
    }

    return CustomerProfile(
      id: id,
      displayName: json['displayName'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: _email(json['emailAddress']),
      phone: _phone(json['phoneNumber']),
      defaultAddress: json['defaultAddress'] is Map<String, Object?>
          ? CustomerAddress.fromShopify(
              json['defaultAddress']! as Map<String, Object?>,
              isDefaultShipping: true,
              isDefaultBilling: true,
            )
          : null,
      defaultBillingAddress:
          json['defaultBillingAddress'] is Map<String, Object?>
          ? CustomerAddress.fromShopify(
              json['defaultBillingAddress']! as Map<String, Object?>,
              isDefaultBilling: true,
            )
          : null,
      marketingPreferences: json['emailAddress'] is Map<String, Object?>
          ? MarketingPreferences.fromEmailAddress(
              json['emailAddress']! as Map<String, Object?>,
            )
          : json['marketingPreferences'] is Map<String, Object?>
          ? MarketingPreferences.fromShopify(
              json['marketingPreferences']! as Map<String, Object?>,
            )
          : null,
    );
  }

  final String id;
  final String? displayName;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final CustomerAddress? defaultAddress;
  final CustomerAddress? defaultBillingAddress;
  final CustomerAccountStatus accountStatus;
  final MarketingPreferences? marketingPreferences;
}

class CustomerAddress {
  const CustomerAddress({
    required this.id,
    this.firstName,
    this.lastName,
    this.company,
    this.address1,
    this.address2,
    this.city,
    this.province,
    this.country,
    this.countryCode,
    this.zip,
    this.phone,
    this.isDefaultShipping = false,
    this.isDefaultBilling = false,
  });

  factory CustomerAddress.fromShopify(
    Map<String, Object?> json, {
    bool isDefaultShipping = false,
    bool isDefaultBilling = false,
  }) {
    final id = json['id'];
    if (id is! String) {
      throw const FormatException('Customer address is missing id.');
    }

    return CustomerAddress(
      id: id,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      company: json['company'] as String?,
      address1: json['address1'] as String?,
      address2: json['address2'] as String?,
      city: json['city'] as String?,
      province: json['province'] as String?,
      country: json['country'] as String?,
      countryCode: json['territoryCode'] as String?,
      zip: json['zip'] as String?,
      phone: json['phone'] as String?,
      isDefaultShipping: isDefaultShipping,
      isDefaultBilling: isDefaultBilling,
    );
  }

  final String id;
  final String? firstName;
  final String? lastName;
  final String? company;
  final String? address1;
  final String? address2;
  final String? city;
  final String? province;
  final String? country;
  final String? countryCode;
  final String? zip;
  final String? phone;
  final bool isDefaultShipping;
  final bool isDefaultBilling;
}

enum CustomerAccountStatus { active, disabled, unknown }

class MarketingPreferences {
  const MarketingPreferences({
    this.acceptsEmailMarketing,
    this.acceptsSmsMarketing,
  });

  factory MarketingPreferences.fromShopify(Map<String, Object?> json) {
    return MarketingPreferences(
      acceptsEmailMarketing: json['acceptsEmailMarketing'] as bool?,
      acceptsSmsMarketing: json['acceptsSmsMarketing'] as bool?,
    );
  }

  factory MarketingPreferences.fromEmailAddress(Map<String, Object?> json) {
    final state = json['marketingState'] as String?;
    return MarketingPreferences(
      acceptsEmailMarketing: state == null ? null : state == 'SUBSCRIBED',
    );
  }

  final bool? acceptsEmailMarketing;
  final bool? acceptsSmsMarketing;
}

String? _email(Object? value) {
  if (value is String) {
    return value;
  }
  if (value is Map<String, Object?>) {
    return value['emailAddress'] as String?;
  }
  return null;
}

String? _phone(Object? value) {
  if (value is String) {
    return value;
  }
  if (value is Map<String, Object?>) {
    return value['phoneNumber'] as String?;
  }
  return null;
}
