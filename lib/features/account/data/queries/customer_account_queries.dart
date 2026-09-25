abstract final class CustomerAccountQueries {
  static const profile = r'''
query CustomerProfile {
  customer {
    id
    displayName
    firstName
    lastName
    emailAddress {
      emailAddress
      marketingState
    }
    phoneNumber {
      phoneNumber
    }
    defaultAddress {
      id
      firstName
      lastName
      company
      address1
      address2
      city
      province
      country
      territoryCode
      zip
      phone: phoneNumber
    }
  }
}
''';

  static const addresses = r'''
query CustomerAddresses {
  customer {
    addresses(first: 50) {
      nodes {
        id
        firstName
        lastName
        company
        address1
        address2
        city
        province
        country
        territoryCode
        zip
        phone: phoneNumber
      }
    }
  }
}
''';

  static const profileUpdate = r'''
mutation CustomerUpdate($input: CustomerUpdateInput!) {
  customerUpdate(input: $input) {
    customer {
      id
      displayName
      firstName
      lastName
    }
    userErrors {
      field
      message
    }
  }
}
''';

  static const addressCreate = r'''
mutation CustomerAddressCreate($address: CustomerAddressInput!) {
  customerAddressCreate(address: $address) {
    customerAddress {
      id
      firstName
      lastName
      company
      address1
      address2
      city
      province
      country
      territoryCode
      zip
      phone: phoneNumber
    }
    userErrors {
      field
      message
    }
  }
}
''';

  static const addressUpdate = r'''
mutation CustomerAddressUpdate($addressId: ID!, $address: CustomerAddressInput, $defaultAddress: Boolean) {
  customerAddressUpdate(addressId: $addressId, address: $address, defaultAddress: $defaultAddress) {
    customerAddress {
      id
      firstName
      lastName
      company
      address1
      address2
      city
      province
      country
      territoryCode
      zip
      phone: phoneNumber
    }
    userErrors {
      field
      message
    }
  }
}
''';

  static const addressDelete = r'''
mutation CustomerAddressDelete($addressId: ID!) {
  customerAddressDelete(addressId: $addressId) {
    deletedAddressId
    userErrors {
      field
      message
    }
  }
}
''';

  static const emailMarketingSubscribe = r'''
mutation CustomerEmailMarketingSubscribe {
  customerEmailMarketingSubscribe {
    emailAddress { emailAddress marketingState }
    userErrors { field message }
  }
}
''';

  static const emailMarketingUnsubscribe = r'''
mutation CustomerEmailMarketingUnsubscribe {
  customerEmailMarketingUnsubscribe {
    emailAddress { emailAddress marketingState }
    userErrors { field message }
  }
}
''';
  static const orders = r'''
query CustomerOrders($first: Int!, $after: String) {
  customer {
    orders(first: $first, after: $after, reverse: true) {
      nodes {
        id
        name
        processedAt
        financialStatus
        fulfillmentStatus
        totalPrice { amount currencyCode }
        subtotal { amount currencyCode }
        totalShipping { amount currencyCode }
        totalTax { amount currencyCode }
        shippingAddress { id address1 address2 city province country zip }
        billingAddress { id address1 address2 city province country zip }
        lineItems(first: 50) {
          nodes {
            name
            quantity
            variantTitle
            sku
            totalPrice { amount currencyCode }
            variantOptions { name value }
          }
        }
        fulfillments(first: 10) {
          nodes {
            status
            trackingInformation { company number url }
          }
        }
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
}
''';
}
