import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flutter/material.dart';

class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({this.label = 'Loading', super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      liveRegion: true,
      child: const Center(
        child: SizedBox.square(
          dimension: AppIconSizes.lg,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class AppSkeletonLoader extends StatelessWidget {
  const AppSkeletonLoader({
    this.width = double.infinity,
    this.height = AppTouchTargets.minimum,
    this.borderRadius = AppRadii.sm,
    super.key,
  });

  final double width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading content',
      liveRegion: true,
      child: ExcludeSemantics(
        child: AnimatedContainer(
          duration: AppDurations.slow,
          curve: AppCurves.standard,
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: AppColors.neutral100,
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
    );
  }
}
