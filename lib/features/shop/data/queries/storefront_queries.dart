import 'package:flexwolf/features/shop/data/queries/storefront_fragments.dart';

abstract final class StorefrontQueries {
  static const products =
      '''
${StorefrontFragments.money}
${StorefrontFragments.image}
${StorefrontFragments.pageInfo}
${StorefrontFragments.variant}
${StorefrontFragments.productSummary}
query Products(\$first: Int!, \$after: String) {
  products(first: \$first, after: \$after) {
    nodes {
      ...ProductSummaryFields
    }
    pageInfo {
      ...PageInfoFields
    }
  }
}
''';

  static const productByHandle =
      '''
${StorefrontFragments.money}
${StorefrontFragments.image}
${StorefrontFragments.variant}
${StorefrontFragments.productSummary}
query ProductByHandle(\$handle: String!) {
  product(handle: \$handle) {
    ...ProductSummaryFields
  }
}
''';

  static const productById =
      '''
${StorefrontFragments.money}
${StorefrontFragments.image}
${StorefrontFragments.variant}
${StorefrontFragments.productSummary}
query ProductById(\$id: ID!) {
  product(id: \$id) {
    ...ProductSummaryFields
  }
}
''';

  static const collections =
      '''
${StorefrontFragments.image}
${StorefrontFragments.pageInfo}
${StorefrontFragments.collectionSummary}
query Collections(\$first: Int!, \$after: String) {
  collections(first: \$first, after: \$after) {
    nodes {
      ...CollectionSummaryFields
    }
    pageInfo {
      ...PageInfoFields
    }
  }
}
''';

  static const collectionByHandle =
      '''
${StorefrontFragments.money}
${StorefrontFragments.image}
${StorefrontFragments.pageInfo}
${StorefrontFragments.variant}
${StorefrontFragments.productSummary}
${StorefrontFragments.collectionSummary}
query CollectionByHandle(\$handle: String!, \$first: Int!, \$after: String) {
  collection(handle: \$handle) {
    ...CollectionSummaryFields
    products(first: \$first, after: \$after) {
      nodes {
        ...ProductSummaryFields
      }
      pageInfo {
        ...PageInfoFields
      }
    }
  }
}
''';
  static const cartById =
      '''
${StorefrontFragments.money}
${StorefrontFragments.image}
${StorefrontFragments.cartSummary}
query CartById(\$id: ID!) {
  cart(id: \$id) {
    ...CartSummaryFields
  }
}
''';

  static const cartCreate =
      '''
${StorefrontFragments.money}
${StorefrontFragments.image}
${StorefrontFragments.cartSummary}
mutation CartCreate(\$input: CartInput!) {
  cartCreate(input: \$input) {
    cart {
      ...CartSummaryFields
    }
    userErrors {
      field
      message
    }
  }
}
''';

  static const cartLinesAdd =
      '''
${StorefrontFragments.money}
${StorefrontFragments.image}
${StorefrontFragments.cartSummary}
mutation CartLinesAdd(\$cartId: ID!, \$lines: [CartLineInput!]!) {
  cartLinesAdd(cartId: \$cartId, lines: \$lines) {
    cart {
      ...CartSummaryFields
    }
    userErrors {
      field
      message
    }
  }
}
''';

  static const cartLinesUpdate =
      '''
${StorefrontFragments.money}
${StorefrontFragments.image}
${StorefrontFragments.cartSummary}
mutation CartLinesUpdate(\$cartId: ID!, \$lines: [CartLineUpdateInput!]!) {
  cartLinesUpdate(cartId: \$cartId, lines: \$lines) {
    cart {
      ...CartSummaryFields
    }
    userErrors {
      field
      message
    }
  }
}
''';

  static const cartLinesRemove =
      '''
${StorefrontFragments.money}
${StorefrontFragments.image}
${StorefrontFragments.cartSummary}
mutation CartLinesRemove(\$cartId: ID!, \$lineIds: [ID!]!) {
  cartLinesRemove(cartId: \$cartId, lineIds: \$lineIds) {
    cart {
      ...CartSummaryFields
    }
    userErrors {
      field
      message
    }
  }
}
''';

  static const cartBuyerIdentityUpdate =
      r'''
'''
      '${StorefrontFragments.money}\n'
      '${StorefrontFragments.image}\n'
      '${StorefrontFragments.cartSummary}\n'
      r'''
mutation CartBuyerIdentityUpdate($cartId: ID!, $buyerIdentity: CartBuyerIdentityInput!) {
  cartBuyerIdentityUpdate(cartId: $cartId, buyerIdentity: $buyerIdentity) {
    cart {
      ...CartSummaryFields
    }
    userErrors {
      field
      message
    }
  }
}
''';
}
