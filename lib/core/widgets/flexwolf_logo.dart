import 'package:flexwolf/core/constants/app_constants.dart';
import 'package:flutter/material.dart';

class FlexwolfLogo extends StatelessWidget {
  const FlexwolfLogo({this.compact = false, this.inverse = false, super.key});

  final bool compact;
  final bool inverse;

  @override
  Widget build(BuildContext context) {
    final useWhite = inverse || Theme.of(context).brightness == Brightness.dark;
    final size = compact ? 42.0 : 64.0;

    return Semantics(
      label: AppConstants.brandName,
      header: true,
      child: ExcludeSemantics(
        child: Image.asset(
          useWhite
              ? 'assets/images/flexwolf_logo_white.png'
              : 'assets/images/flexwolf_logo_black.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
      ),
    );
  }
}
