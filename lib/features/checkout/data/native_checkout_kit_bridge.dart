import 'package:flexwolf/core/errors/app_exception.dart';
import 'package:flexwolf/core/security/security_policy.dart';
import 'package:flexwolf/features/checkout/domain/checkout_result.dart';
import 'package:flutter/services.dart';

abstract interface class NativeCheckoutKitBridge {
  Future<CheckoutResult> presentCheckout(Uri checkoutUrl);

  Future<void> preloadCheckout(Uri checkoutUrl);
}

class MethodChannelCheckoutKitBridge
    implements NativeCheckoutKitBridge, CheckoutPresenter {
  const MethodChannelCheckoutKitBridge();

  static const _channel = MethodChannel('com.flexwolf.flexwolf/checkout_kit');

  @override
  Future<CheckoutResult> presentCheckout(Uri checkoutUrl) async {
    SecurityPolicy.requireHttpsUri(
      checkoutUrl,
      context: 'Shopify checkout URL',
    );
    try {
      final response = await _channel.invokeMapMethod<String, Object?>(
        'presentCheckout',
        <String, Object?>{'checkoutUrl': checkoutUrl.toString()},
      );
      return switch (response?['status']) {
        'completed' => CheckoutResult.completed(
          orderId: response?['orderId'] as String?,
          orderName: response?['orderName'] as String?,
        ),
        'cancelled' => const CheckoutResult.cancelled(),
        'closed' => const CheckoutResult.closed(),
        'failed' => CheckoutResult.failed(
          response?['message'] as String? ?? 'Checkout could not be completed.',
        ),
        _ => const CheckoutResult.failed(
          'Checkout Kit returned an invalid response.',
        ),
      };
    } on MissingPluginException catch (error) {
      throw AppException(
        kind: AppErrorKind.checkout,
        message: 'In-app checkout is unavailable on this device.',
        code: 'checkout_kit_unavailable',
        cause: error,
      );
    } on PlatformException catch (error) {
      throw AppException(
        kind: AppErrorKind.checkout,
        message: error.message ?? 'In-app checkout could not be opened.',
        code: error.code,
        cause: error,
        isRetryable: true,
      );
    }
  }

  @override
  Future<void> preloadCheckout(Uri checkoutUrl) async {
    SecurityPolicy.requireHttpsUri(
      checkoutUrl,
      context: 'Shopify checkout URL',
    );
    await _channel.invokeMethod<void>('preloadCheckout', <String, Object?>{
      'checkoutUrl': checkoutUrl.toString(),
    });
  }

  @override
  Future<CheckoutResult> present(CheckoutSessionRequest request) =>
      presentCheckout(request.checkoutUrl);
}
