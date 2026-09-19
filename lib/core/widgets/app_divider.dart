import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flutter/material.dart';

class AppDivider extends StatelessWidget {
  const AppDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(height: AppSpacing.lg, thickness: AppBorders.thin);
  }
}
