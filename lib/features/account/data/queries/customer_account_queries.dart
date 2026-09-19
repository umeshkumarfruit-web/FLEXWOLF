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
    }
    userErrors {
      field
      message
    }
  }
}
''';

  static const addressUpdate = r'''
mutation CustomerAddressUpdate($id: ID!, $address: CustomerAddressInput!) {
  customerAddressUpdate(id: $id, address: $address) {
    customerAddress {
      id
    }
    userErrors {
      field
      message
    }
  }
}
''';

  static const addressDelete = r'''
mutation CustomerAddressDelete($id: ID!) {
  customerAddressDelete(id: $id) {
    deletedAddressId
    userErrors {
      field
      message
    }
  }
}
''';
  static const orders = r'''
query CustomerOrders($first: Int!, $after: String) {
  customer {
    orders(first: $first, after: $after) {
      nodes {
        id
        name
        processedAt
        financialStatus
        fulfillmentStatus
        displayFulfillmentStatus
        totalPrice { amount currencyCode }
        subtotalPrice { amount currencyCode }
        totalDiscounts { amount currencyCode }
        totalShippingPrice { amount currencyCode }
        totalTax { amount currencyCode }
        shippingAddress { id address1 address2 city province country zip }
        billingAddress { id address1 address2 city province country zip }
        lineItems(first: 50) {
          nodes {
            title
            quantity
            variantTitle
            sku
            discountedTotalPrice { amount currencyCode }
            selectedOptions { name value }
          }
        }
        fulfillments {
          status
          trackingCompany
          trackingNumber
          trackingUrl
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
