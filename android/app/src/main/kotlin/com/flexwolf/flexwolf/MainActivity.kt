package com.flexwolf.flexwolf

import android.net.Uri
import com.shopify.checkoutsheetkit.CheckoutException
import com.shopify.checkoutsheetkit.CheckoutSheetKitDialog
import com.shopify.checkoutsheetkit.DefaultCheckoutEventProcessor
import com.shopify.checkoutsheetkit.ShopifyCheckoutSheetKit
import com.shopify.checkoutsheetkit.lifecycleevents.CheckoutCompletedEvent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    companion object {
        private const val CHECKOUT_CHANNEL = "com.flexwolf.flexwolf/checkout_kit"
    }

    private var pendingCheckoutResult: MethodChannel.Result? = null
    private var checkoutDialog: CheckoutSheetKitDialog? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHECKOUT_CHANNEL,
        ).setMethodCallHandler(::handleCheckoutCall)
    }

    private fun handleCheckoutCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "presentCheckout" -> presentCheckout(call, result)
            "preloadCheckout" -> preloadCheckout(call, result)
            else -> result.notImplemented()
        }
    }

    private fun checkoutUrl(call: MethodCall, result: MethodChannel.Result): String? {
        val url = call.argument<String>("checkoutUrl")
        val uri = url?.let(Uri::parse)
        if (url.isNullOrBlank() || uri?.scheme != "https" || uri.host.isNullOrBlank()) {
            result.error(
                "invalid_checkout_url",
                "A valid HTTPS Shopify checkout URL is required.",
                null,
            )
            return null
        }
        return url
    }

    private fun presentCheckout(call: MethodCall, result: MethodChannel.Result) {
        val url = checkoutUrl(call, result) ?: return
        if (pendingCheckoutResult != null) {
            result.error(
                "checkout_in_progress",
                "Another checkout is already open.",
                null,
            )
            return
        }

        pendingCheckoutResult = result
        val eventProcessor = object : DefaultCheckoutEventProcessor(this@MainActivity) {
            override fun onCheckoutCompleted(event: CheckoutCompletedEvent) {
                finishCheckout(
                    mapOf(
                        "status" to "completed",
                        "orderId" to event.orderDetails.id,
                    ),
                )
            }

            override fun onCheckoutCanceled() {
                finishCheckout(mapOf("status" to "cancelled"))
            }

            override fun onCheckoutFailed(error: CheckoutException) {
                finishCheckout(
                    mapOf(
                        "status" to "failed",
                        "message" to error.errorDescription,
                    ),
                )
            }
        }

        try {
            checkoutDialog = ShopifyCheckoutSheetKit.present(url, this, eventProcessor)
        } catch (error: Exception) {
            pendingCheckoutResult = null
            checkoutDialog = null
            result.error(
                "checkout_launch_failed",
                error.message ?: "The secure checkout sheet could not be opened.",
                null,
            )
        }
    }

    private fun preloadCheckout(call: MethodCall, result: MethodChannel.Result) {
        val url = checkoutUrl(call, result) ?: return
        try {
            ShopifyCheckoutSheetKit.preload(url, this)
            result.success(null)
        } catch (error: Exception) {
            result.error(
                "checkout_preload_failed",
                error.message ?: "Checkout could not be prepared.",
                null,
            )
        }
    }

    private fun finishCheckout(payload: Map<String, String?>) {
        val result = pendingCheckoutResult ?: return
        pendingCheckoutResult = null
        checkoutDialog = null
        result.success(payload)
    }

    override fun onDestroy() {
        checkoutDialog?.dismiss()
        checkoutDialog = null
        pendingCheckoutResult = null
        super.onDestroy()
    }
}
