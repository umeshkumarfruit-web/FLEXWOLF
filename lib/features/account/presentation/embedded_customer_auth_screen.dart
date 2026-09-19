import 'dart:async';

import 'package:flexwolf/app/router/root_navigator.dart';
import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class EmbeddedCustomerAuthPresenter {
  EmbeddedCustomerAuthPresenter({
    required this.redirectUri,
    WebViewCookieManager? cookieManager,
  }) : _cookieManager = cookieManager ?? WebViewCookieManager();

  final Uri redirectUri;
  final WebViewCookieManager _cookieManager;
  final _callbacks = StreamController<Uri>.broadcast(sync: true);
  bool _isOpen = false;

  Stream<Uri> get callbackStream => _callbacks.stream;

  Future<bool> launch(Uri authorizationUri) async {
    final navigator = rootNavigatorKey.currentState;
    if (navigator == null || _isOpen) return false;

    _isOpen = true;
    final expectedState = authorizationUri.queryParameters['state'];
    final route = MaterialPageRoute<Uri>(
      fullscreenDialog: true,
      builder: (_) => EmbeddedCustomerAuthScreen(
        authorizationUri: authorizationUri,
        redirectUri: redirectUri,
      ),
    );
    unawaited(_present(navigator, route, expectedState));
    return true;
  }

  Future<void> _present(
    NavigatorState navigator,
    MaterialPageRoute<Uri> route,
    String? expectedState,
  ) async {
    Uri? callback;
    try {
      callback = await navigator.push(route);
    } finally {
      _isOpen = false;
      if (!_callbacks.isClosed) {
        _callbacks.add(
          callback ??
              redirectUri.replace(
                queryParameters: <String, String>{
                  'error': 'access_denied',
                  'state': ?expectedState,
                },
              ),
        );
      }
    }
  }

  Future<void> clearSession() async {
    await _cookieManager.clearCookies();
  }

  Future<void> dispose() => _callbacks.close();
}

class EmbeddedCustomerAuthScreen extends StatefulWidget {
  const EmbeddedCustomerAuthScreen({
    required this.authorizationUri,
    this.redirectUri,
    this.title = 'FLEXWOLF ACCOUNT',
    super.key,
  });

  final Uri authorizationUri;
  final Uri? redirectUri;
  final String title;

  @override
  State<EmbeddedCustomerAuthScreen> createState() =>
      _EmbeddedCustomerAuthScreenState();
}

class _EmbeddedCustomerAuthScreenState
    extends State<EmbeddedCustomerAuthScreen> {
  late final WebViewController _controller;
  var _progress = 0;
  String? _pageError;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setBackgroundColor(Colors.white)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent('FLEXWOLF Mobile App')
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _pageError = null);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == false || !mounted) return;
            setState(() {
              _pageError = 'Account page could not load. Check your connection and retry.';
            });
          },
          onHttpError: (error) {
            final request = error.request;
            final response = error.response;
            if (!mounted || request == null || response == null) return;
            if (request.uri.path != widget.authorizationUri.path) return;
            if (response.statusCode < 400) return;
            setState(() {
              _pageError = response.statusCode == 400
                  ? 'Shopify rejected this app\'s Customer Account client ID or callback URL. Update the mobile client in Shopify, then retry.'
                  : 'Shopify account service returned HTTP ${response.statusCode}. Please retry.';
            });
          },
          onNavigationRequest: _handleNavigation,
        ),
      )
      ..loadRequest(widget.authorizationUri);
  }

  NavigationDecision _handleNavigation(NavigationRequest request) {
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.prevent;
    if (_matchesRedirect(uri)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop(uri);
      });
      return NavigationDecision.prevent;
    }

    if (uri.scheme == 'about') return NavigationDecision.navigate;
    if (_isShopifyAuthenticationHost(uri)) {
      return NavigationDecision.navigate;
    }
    if (mounted) {
      setState(() {
        _pageError = 'Only the secure Shopify account screen can open here. The storefront was blocked.';
      });
    }
    return NavigationDecision.prevent;
  }

  bool _isShopifyAuthenticationHost(Uri uri) {
    if (uri.scheme != 'https') return false;
    final host = uri.host.toLowerCase();
    final initialHost = widget.authorizationUri.host.toLowerCase();
    return host == initialHost ||
        host == 'shopify.com' ||
        host.endsWith('.shopify.com') ||
        host == 'shop.app' ||
        host.endsWith('.shop.app');
  }

  bool _matchesRedirect(Uri uri) {
    final expected = widget.redirectUri;
    if (expected == null) return false;
    return uri.scheme == expected.scheme &&
        uri.host == expected.host &&
        uri.port == expected.port &&
        uri.path == expected.path;
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(brightness: Brightness.light),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            tooltip: 'Close account login',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
          title: Text(widget.title),
          bottom: _progress < 100
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(2),
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    value: _progress / 100,
                    color: Colors.black,
                    backgroundColor: AppColors.surfaceMuted,
                  ),
                )
              : null,
        ),
        body: _pageError == null
            ? WebViewWidget(controller: _controller)
            : Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_outlined, size: 40),
                      const SizedBox(height: AppSpacing.md),
                      Text(_pageError!, textAlign: TextAlign.center),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton(
                        onPressed: () => _controller.reload(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
