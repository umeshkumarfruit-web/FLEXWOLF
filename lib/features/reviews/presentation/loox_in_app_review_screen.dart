import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Loox only accepts customer submissions through its hosted review form.
/// This keeps that form inside the app instead of launching a browser.
class LooxInAppReviewScreen extends StatefulWidget {
  const LooxInAppReviewScreen({
    required this.productHandle,
    required this.productTitle,
    super.key,
  });

  final String productHandle;
  final String productTitle;

  @override
  State<LooxInAppReviewScreen> createState() => _LooxInAppReviewScreenState();
}

class _LooxInAppReviewScreenState extends State<LooxInAppReviewScreen> {
  late final WebViewController _controller;
  var _loading = true;
  String? _error;

  Uri get _reviewUrl => Uri.https(
    'flexwolf.co',
    '/products/${widget.productHandle}',
    const {'ref': 'review'},
  );

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _loading = true;
                _error = null;
              });
            }
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _loading = false);
            }
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted) {
              setState(() {
                _loading = false;
                _error = 'Review form could not load.';
              });
            }
          },
          onNavigationRequest: (request) {
            if (!request.isMainFrame) {
              return NavigationDecision.navigate;
            }
            final uri = Uri.tryParse(request.url);
            if (uri == null || uri.scheme != 'https') {
              return NavigationDecision.prevent;
            }
            final isStore =
                uri.host == 'flexwolf.co' || uri.host == 'www.flexwolf.co';
            final isLoox =
                uri.host == 'loox.io' || uri.host.endsWith('.loox.io');
            if (!isStore && !isLoox) {
              return NavigationDecision.prevent;
            }
            if (isStore && uri.path != '/products/${widget.productHandle}') {
              // Loox can redirect after submission; return to the app product page.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) Navigator.of(context).pop(true);
              });
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(_reviewUrl);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('Review ${widget.productTitle}')),
    body: Stack(
      children: [
        WebViewWidget(controller: _controller),
        if (_loading) const Center(child: CircularProgressIndicator()),
        if (_error != null)
          ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => _controller.loadRequest(_reviewUrl),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}
