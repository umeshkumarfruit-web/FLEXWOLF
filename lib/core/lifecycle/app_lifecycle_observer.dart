import 'package:flexwolf/core/logging/app_logger.dart';
import 'package:flutter/widgets.dart';

class AppLifecycleObserver extends StatefulWidget {
  const AppLifecycleObserver({
    required this.child,
    required this.logger,
    super.key,
  });

  final Widget child;
  final AppLogger logger;

  @override
  State<AppLifecycleObserver> createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends State<AppLifecycleObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    widget.logger.debug('Lifecycle changed: ${state.name}');
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
