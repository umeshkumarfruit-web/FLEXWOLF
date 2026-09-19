import 'package:flexwolf/app/config/app_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EnvironmentLabel extends ConsumerWidget {
  const EnvironmentLabel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    if (config.environment.isProduction) {
      return const SizedBox.shrink();
    }

    return Text(
      config.environment.label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall,
    );
  }
}
