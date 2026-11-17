import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'theme/app_colors.dart';
import 'theme/app_spacing.dart';

export 'theme/app_colors.dart';
export 'theme/app_spacing.dart';

abstract final class AppTheme {
  // Aliases retained for backwards compatibility
  static const green = AppColors.green;
  static const dark = AppColors.dark;
  static const background = AppColors.background;
  static const gold = AppColors.gold;
  static const muted = AppColors.muted;

  static final light = ThemeData(
    useMaterial3: true,
    fontFamily: 'Cairo',
    materialTapTargetSize: MaterialTapTargetSize.padded,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.green,
      primary: AppColors.green,
      secondary: AppColors.goldText,
      surface: AppColors.background,
    ),
    scaffoldBackgroundColor: AppColors.background,
    dividerColor: AppColors.cardBorder,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.dark,
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleTextStyle: TextStyle(
        fontFamily: 'Cairo',
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.dark,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      height: 80,
      backgroundColor: AppColors.surfaceWhite,
      indicatorColor: AppColors.tagBackground,
      surfaceTintColor: Colors.transparent,
      indicatorShape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: AppColors.green, size: 24);
        }
        return const IconThemeData(color: AppColors.muted, size: 22);
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontFamily: 'Cairo',
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.green,
          );
        }
        return const TextStyle(
          fontFamily: 'Cairo',
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: AppColors.muted,
        );
      }),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surfaceWhite,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceWhite,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md + 2,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        borderSide: const BorderSide(color: AppColors.green, width: 1.8),
      ),
      hintStyle: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 13.5,
        color: AppColors.muted,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        disabledBackgroundColor: AppColors.progressTrack,
        disabledForegroundColor: AppColors.dark,
        elevation: 0,
        minimumSize: const Size(0, AppSpacing.buttonHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
          fontSize: 15.5,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.green,
        backgroundColor: AppColors.surfaceWhite,
        minimumSize: const Size(0, AppSpacing.outlinedButtonHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm + 2,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        side: const BorderSide(color: AppColors.inputBorder),
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
          fontSize: 14.5,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.green,
        minimumSize: const Size(
          AppSpacing.minTouchTarget,
          AppSpacing.minTouchTarget,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Cairo',
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surfaceWhite,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusHero),
      ),
      titleTextStyle: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.dark,
      ),
      contentTextStyle: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 14.5,
        color: AppColors.muted,
        height: 1.55,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColors.surfaceWhite,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusHero + 4),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.dark,
      contentTextStyle: const TextStyle(
        fontFamily: 'Cairo',
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: AppColors.surfaceWhite,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
