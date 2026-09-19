import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flexwolf/core/security/security_policy.dart';
import 'package:flexwolf/core/widgets/app_image_container.dart';
import 'package:flexwolf/core/widgets/app_loading_indicator.dart';
import 'package:flutter/material.dart';

class AppRemoteImage extends StatelessWidget {
  const AppRemoteImage({
    required this.imageUrl,
    this.semanticLabel,
    this.aspectRatio = AppAspectRatios.square,
    super.key,
  });

  final String imageUrl;
  final String? semanticLabel;
  final double aspectRatio;

  @override
  Widget build(BuildContext context) {
    if (!SecurityPolicy.isHttpsUrl(imageUrl)) {
      return AppImageContainer(
        semanticLabel: semanticLabel,
        aspectRatio: aspectRatio,
        child: const Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: AppIconSizes.lg,
          ),
        ),
      );
    }

    return AppImageContainer(
      semanticLabel: semanticLabel,
      aspectRatio: aspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Image.network(
            imageUrl,
            fit: BoxFit.cover,
            semanticLabel: semanticLabel,
            cacheWidth: _cacheWidthFor(context, constraints),
            filterQuality: FilterQuality.medium,
            gaplessPlayback: true,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded || frame != null) {
                return child;
              }
              return const AppSkeletonLoader();
            },
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  size: AppIconSizes.lg,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

int? _cacheWidthFor(BuildContext context, BoxConstraints constraints) {
  final media = MediaQuery.maybeOf(context);
  if (media == null) return null;

  // Decode each image close to its painted width. Product cards are much
  // narrower than the screen, so decoding every thumbnail at full screen
  // resolution wastes several MB per image and causes GC/jank while scrolling.
  final logicalWidth = constraints.hasBoundedWidth && constraints.maxWidth > 0
      ? constraints.maxWidth
      : media.size.shortestSide;
  final width = (logicalWidth * media.devicePixelRatio).ceil();
  return width.clamp(64, 1440).toInt();
}
