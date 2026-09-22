import 'package:flexwolf/core/storage/local_storage.dart';
import 'package:flexwolf/features/shop/data/public_cart_repository.dart';
import 'package:flexwolf/features/shop/domain/cart.dart';
import 'package:flexwolf/features/shop/domain/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('guest bag persists items and builds a real Shopify cart permalink', () async {
    final storage = InMemoryLocalStorage();
    final repository = PublicCartRepository(storage);
    await repository.createCart();
    final first = await repository.addLines(PublicCartRepository.cartId, [
      CartLineInput(
        merchandiseId: 'gid://shopify/ProductVariant/48087833673985',
        quantity: 1,
        title: 'Wolfmark Wrap Tee',
        variantTitle: 'White / S',
        price: Money(amount: DecimalAmount.parse('30.00'), currencyCode: 'USD'),
      ),
    ]);
    expect(first.totalQuantity, 1);
    expect(first.lines.single.title, 'Wolfmark Wrap Tee');
    expect(first.checkoutUrl.toString(),
        'https://flexwolf.co/cart/48087833673985:1');

    final restored = await PublicCartRepository(storage)
        .fetchCart(PublicCartRepository.cartId);
    expect(restored?.lines.single.title, 'Wolfmark Wrap Tee');
    final updated = await repository.updateLines(PublicCartRepository.cartId, [
      const CartLineInput(
        merchandiseId: 'gid://shopify/ProductVariant/48087833673985',
        quantity: 2,
      ),
    ]);
    expect(updated.totalQuantity, 2);
    expect(updated.subtotal?.amount.value, '60.00');
    expect(updated.checkoutUrl.toString(),
        'https://flexwolf.co/cart/48087833673985:2');
  });
}