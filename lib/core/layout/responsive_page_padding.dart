import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flutter/material.dart';

class ResponsivePagePadding extends StatelessWidget {
  const ResponsivePagePadding({
    required this.child,
    this.constrainWidth = true,
    this.includeVertical = true,
    super.key,
  });

  final Widget child;
  final bool constrainWidth;
  final bool includeVertical;

  static double horizontalPaddingFor(double width) {
    if (width < AppBreakpoints.smallPhone) {
      return AppScreenPadding.compact;
    }
    if (width < AppBreakpoints.largePhone) {
      return AppScreenPadding.regular;
    }
    return AppScreenPadding.comfortable;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = horizontalPaddingFor(width);
    final viewInsets = MediaQuery.viewInsetsOf(context);

    final padded = Padding(
      padding: EdgeInsets.fromLTRB(
        horizontal,
        includeVertical ? AppSpacing.md : AppSpacing.zero,
        horizontal,
        (includeVertical ? AppSpacing.md : AppSpacing.zero) + viewInsets.bottom,
      ),
      child: child,
    );

    if (!constrainWidth) {
      return padded;
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppScreenPadding.maxContentWidth,
        ),
        child: padded,
      ),
    );
  }
}

class ResponsiveSafeArea extends StatelessWidget {
  const ResponsiveSafeArea({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      maintainBottomViewPadding: true,
      child: MediaQuery.withClampedTextScaling(
        minScaleFactor: 1,
        maxScaleFactor: 1.3,
        child: child,
      ),
    );
  }
}

enum AppWidthClass { smallPhone, phone, largePhone, tablet }

extension AppResponsiveContext on BuildContext {
  AppWidthClass get widthClass {
    final width = MediaQuery.sizeOf(this).width;
    if (width < AppBreakpoints.smallPhone) {
      return AppWidthClass.smallPhone;
    }
    if (width < AppBreakpoints.phone) {
      return AppWidthClass.phone;
    }
    if (width < AppBreakpoints.tablet) {
      return AppWidthClass.largePhone;
    }
    return AppWidthClass.tablet;
  }

  bool get isNarrow => widthClass == AppWidthClass.smallPhone;
}
