abstract final class StorefrontFragments {
  static const money = r'''
fragment MoneyFields on MoneyV2 {
  amount
  currencyCode
}
''';

  static const image = r'''
fragment ImageFields on Image {
  url
  altText
  width
  height
}
''';

  static const pageInfo = r'''
fragment PageInfoFields on PageInfo {
  hasNextPage
  endCursor
}
''';

  static const variant = r'''
fragment VariantFields on ProductVariant {
  id
  title
  sku
  availableForSale
  currentlyNotInStock
  selectedOptions {
    name
    value
  }
  price {
    ...MoneyFields
  }
  compareAtPrice {
    ...MoneyFields
  }
  image {
    ...ImageFields
  }
}
''';

  static const productSummary = r'''
fragment ProductSummaryFields on Product {
  id
  handle
  title
  description
  descriptionHtml
  productType
  vendor
  tags
  availableForSale
  updatedAt
  featuredImage {
    ...ImageFields
  }
  options {
    id
    name
    values
  }
  images(first: 8) {
    nodes {
      ...ImageFields
    }
  }
  variants(first: 50) {
    nodes {
      ...VariantFields
    }
  }
}
''';

  static const collectionSummary = r'''
fragment CollectionSummaryFields on Collection {
  id
  handle
  title
  description
  image {
    ...ImageFields
  }
}
''';
  static const cartSummary = r'''
fragment CartSummaryFields on Cart {
  id
  checkoutUrl
  totalQuantity
  buyerIdentity {
    countryCode
    email
    phone
  }
  cost {
    subtotalAmount {
      ...MoneyFields
    }
    totalAmount {
      ...MoneyFields
    }
  }
  lines(first: 50) {
    nodes {
      id
      quantity
      merchandise {
        ... on ProductVariant {
          id
          title
          product {
            title
          }
          price {
            ...MoneyFields
          }
          image {
            ...ImageFields
          }
        }
      }
    }
  }
}
''';
}
