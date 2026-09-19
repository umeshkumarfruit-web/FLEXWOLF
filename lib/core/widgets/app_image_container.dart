import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flutter/material.dart';

class AppImageContainer extends StatelessWidget {
  const AppImageContainer({
    required this.child,
    this.semanticLabel,
    this.aspectRatio = AppAspectRatios.square,
    this.backgroundColor = AppColors.surfaceMuted,
    this.borderRadius = AppRadii.sm,
    super.key,
  });

  final Widget child;
  final String? semanticLabel;
  final double aspectRatio;
  final Color backgroundColor;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final image = AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: ColoredBox(color: backgroundColor, child: child),
      ),
    );

    if (semanticLabel == null) {
      return image;
    }

    return Semantics(image: true, label: semanticLabel, child: image);
  }
}
