import 'package:flutter/material.dart';

abstract final class AppColors {
  // FLEXWOLF visual reference: black/white/neutral athletic streetwear.
  // Exact production brand values remain configurable until final approval.
  static const black = Color(0xFF000000);
  static const white = Color(0xFFFFFFFF);
  static const neutral950 = Color(0xFF0A0A0A);
  static const neutral900 = Color(0xFF151515);
  static const neutral800 = Color(0xFF242424);
  static const neutral700 = Color(0xFF3F3F3F);
  static const neutral600 = Color(0xFF5F5F5F);
  static const neutral500 = Color(0xFF7A7A7A);
  static const neutral300 = Color(0xFFD6D6D6);
  static const neutral200 = Color(0xFFE8E8E8);
  static const neutral100 = Color(0xFFF5F5F3);
  static const neutral50 = Color(0xFFFAFAF8);

  static const brand = black;
  static const background = white;
  static const inverseBackground = black;
  static const surface = white;
  static const surfaceMuted = neutral100;
  static const surfacePressed = neutral200;
  static const textPrimary = black;
  static const textSecondary = neutral700;
  static const textMuted = neutral600;
  static const textInverse = white;
  static const border = neutral200;
  static const borderStrong = neutral900;
  static const divider = neutral200;

  static const sale = Color(0xFFB42318);
  static const error = Color(0xFFB42318);
  static const success = Color(0xFF166534);
  static const warning = Color(0xFF8A4B00);
}

abstract final class AppSpacing {
  static const zero = 0.0;
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const xxxl = 64.0;
}

abstract final class AppScreenPadding {
  static const compact = 16.0;
  static const regular = 20.0;
  static const comfortable = 24.0;
  static const maxContentWidth = 640.0;
}

abstract final class AppRadii {
  static const none = 0.0;
  static const xs = 2.0;
  static const sm = 2.0;
  static const md = 4.0;
  static const lg = 4.0;
  static const pill = 999.0;
}

abstract final class AppBorders {
  static const thin = 1.0;
  static const strong = 1.5;
}

abstract final class AppElevations {
  static const none = 0.0;
  static const raised = 1.0;
  static const modal = 8.0;
}

abstract final class AppIconSizes {
  static const xs = 16.0;
  static const sm = 18.0;
  static const md = 24.0;
  static const lg = 32.0;
}

abstract final class AppTouchTargets {
  static const minimum = 48.0;
  static const comfortable = 56.0;
}

abstract final class AppButtonSizes {
  static const minHeight = AppTouchTargets.comfortable;
  static const compactHeight = AppTouchTargets.minimum;
  static const horizontalPadding = 20.0;
}

abstract final class AppDurations {
  static const instant = Duration.zero;
  static const fast = Duration(milliseconds: 120);
  static const normal = Duration(milliseconds: 200);
  static const slow = Duration(milliseconds: 320);
}

abstract final class AppCurves {
  static const standard = Curves.easeOutCubic;
  static const emphasized = Curves.easeInOutCubic;
}

abstract final class AppBreakpoints {
  static const smallPhone = 360.0;
  static const compact = smallPhone;
  static const phone = 430.0;
  static const largePhone = 600.0;
  static const medium = largePhone;
  static const tablet = 840.0;
  static const expanded = tablet;
}

abstract final class AppAspectRatios {
  static const productCard = 4 / 5;
  static const productHero = 3 / 4;
  static const banner = 16 / 9;
  static const square = 1.0;
}

abstract final class AppTypography {
  static const String fontFamily = 'Karla';
  static const letterSpacing = 0.0;

  static const display = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.06,
    letterSpacing: 2.8,
  );

  static const pageTitle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: 2.1,
  );

  static const sectionTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: 2.4,
  );

  static const productTitle = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: letterSpacing,
  );

  static const body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.45,
    letterSpacing: letterSpacing,
  );

  static const bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: letterSpacing,
  );

  static const cta = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 1.6,
  );

  static const price = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: letterSpacing,
  );

  static const salePrice = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: letterSpacing,
    color: AppColors.sale,
  );

  static const label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: 1.25,
  );

  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.35,
    letterSpacing: letterSpacing,
  );

  static const navigationLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.4,
  );
}
