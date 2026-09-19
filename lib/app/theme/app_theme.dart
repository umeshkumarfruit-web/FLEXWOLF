import 'package:flexwolf/core/design/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: AppColors.brand,
      onPrimary: AppColors.textInverse,
      secondary: AppColors.neutral900,
      onSecondary: AppColors.textInverse,
      error: AppColors.error,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      outline: AppColors.border,
      outlineVariant: AppColors.border,
    ),
    scaffoldBackground: AppColors.background,
    surface: AppColors.surface,
    surfaceMuted: AppColors.neutral100,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    divider: AppColors.divider,
    overlayStyle: SystemUiOverlayStyle.dark,
  );

  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.white,
      onPrimary: AppColors.black,
      secondary: AppColors.neutral200,
      onSecondary: AppColors.black,
      error: AppColors.error,
      surface: AppColors.neutral900,
      onSurface: AppColors.white,
      outline: AppColors.neutral700,
      outlineVariant: AppColors.neutral800,
      inverseSurface: AppColors.white,
      onInverseSurface: AppColors.black,
    ),
    scaffoldBackground: AppColors.black,
    surface: AppColors.neutral900,
    surfaceMuted: AppColors.neutral800,
    textPrimary: AppColors.white,
    textSecondary: AppColors.neutral300,
    divider: AppColors.neutral800,
    overlayStyle: SystemUiOverlayStyle.light,
  );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme colorScheme,
    required Color scaffoldBackground,
    required Color surface,
    required Color surfaceMuted,
    required Color textPrimary,
    required Color textSecondary,
    required Color divider,
    required SystemUiOverlayStyle overlayStyle,
  }) {
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackground,
      fontFamily: AppTypography.fontFamily,
      textTheme: const TextTheme(
        displaySmall: AppTypography.display,
        headlineSmall: AppTypography.pageTitle,
        titleLarge: AppTypography.sectionTitle,
        titleMedium: AppTypography.productTitle,
        bodyLarge: AppTypography.body,
        bodyMedium: AppTypography.body,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.cta,
        labelMedium: AppTypography.label,
        labelSmall: AppTypography.caption,
      ).apply(bodyColor: textPrimary, displayColor: textPrimary),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: AppElevations.none,
        scrolledUnderElevation: AppElevations.none,
        backgroundColor: scaffoldBackground,
        foregroundColor: textPrimary,
        systemOverlayStyle: overlayStyle,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w900,
          height: 1.1,
          letterSpacing: AppTypography.letterSpacing,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: scaffoldBackground,
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppTypography.navigationLabel.copyWith(
            color: states.contains(WidgetState.selected)
                ? textPrimary
                : textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? textPrimary
                : textSecondary,
            size: AppIconSizes.md,
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: divider,
        thickness: AppBorders.thin,
        space: AppSpacing.lg,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: isDark ? AppColors.white : AppColors.black,
        disabledColor: surfaceMuted,
        labelStyle: AppTypography.label.copyWith(color: textPrimary),
        secondaryLabelStyle: AppTypography.label.copyWith(
          color: isDark ? AppColors.black : AppColors.white,
        ),
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: const StadiumBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: _inputBorder(colorScheme.outlineVariant),
        enabledBorder: _inputBorder(colorScheme.outlineVariant),
        focusedBorder: _inputBorder(textPrimary),
        errorBorder: _inputBorder(AppColors.error),
        focusedErrorBorder: _inputBorder(AppColors.error),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppButtonSizes.minHeight),
          backgroundColor: isDark ? AppColors.white : AppColors.black,
          foregroundColor: isDark ? AppColors.black : AppColors.white,
          disabledBackgroundColor: AppColors.neutral600,
          disabledForegroundColor: AppColors.neutral300,
          textStyle: AppTypography.cta,
          shape: const RoundedRectangleBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppButtonSizes.minHeight),
          foregroundColor: textPrimary,
          disabledForegroundColor: textSecondary,
          textStyle: AppTypography.cta,
          side: BorderSide(color: textPrimary),
          shape: const RoundedRectangleBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(
            AppTouchTargets.minimum,
            AppTouchTargets.minimum,
          ),
          foregroundColor: textPrimary,
          textStyle: AppTypography.cta,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        elevation: AppElevations.modal,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadii.lg),
          ),
        ),
      ),
    );
  }

  static OutlineInputBorder _inputBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.sm),
      borderSide: BorderSide(color: color),
    );
  }
}
