import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_spacing.dart';
import '../responsive/app_layout.dart';
import '../navigation/app_page_transition.dart';

abstract final class AppTheme {
  static ButtonStyle categoryButton({required bool selected}) =>
      OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        backgroundColor: selected
            ? AppColors.navigationSelected
            : AppColors.surface,
        side: const BorderSide(color: AppColors.primary),
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.pill),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
      );
  static const gameInputDecoration = InputDecoration(
    isDense: true,
    filled: true,
    fillColor: AppColors.surface,
    contentPadding: EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.md,
    ),
    border: OutlineInputBorder(
      borderRadius: AppRadii.small,
      borderSide: BorderSide(color: AppColors.fieldBorder, width: 2.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: AppRadii.small,
      borderSide: BorderSide(color: AppColors.fieldBorder, width: 2.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: AppRadii.small,
      borderSide: BorderSide(color: AppColors.primary, width: 3),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: AppRadii.small,
      borderSide: BorderSide(color: AppColors.danger, width: 2),
    ),
  );
  static ThemeData get light => dark;

  static ThemeData get dark => ThemeData(
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: AppPageTransitionsBuilder(),
        TargetPlatform.iOS: AppPageTransitionsBuilder(),
        TargetPlatform.macOS: AppPageTransitionsBuilder(),
        TargetPlatform.windows: AppPageTransitionsBuilder(),
        TargetPlatform.linux: AppPageTransitionsBuilder(),
        TargetPlatform.fuchsia: AppPageTransitionsBuilder(),
      },
    ),
    fontFamily: AppFonts.reading,
    fontFamilyFallback: AppFonts.fallback,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      onPrimary: AppColors.cave,
      secondary: AppColors.gold,
      surface: AppColors.surface,
      onSurface: AppColors.text,
      error: AppColors.danger,
    ),
    textTheme: ThemeData.dark().textTheme.apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    iconTheme: const IconThemeData(color: AppColors.caveMuted),
    dividerColor: AppColors.helpBorder,
    dialogTheme: const DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: AppColors.transparent,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.cave,
      foregroundColor: AppColors.text,
      surfaceTintColor: AppColors.transparent,
      elevation: 0,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      hintStyle: TextStyle(color: AppColors.textMuted),
    ),
    scaffoldBackgroundColor: AppColors.cave,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.cave,
        minimumSize: const Size.fromHeight(AppLayout.permissionButtonMinHeight),
        textStyle: AppTextStyles.body,
      ),
    ),
    useMaterial3: true,
  );

  static const systemUi = SystemUiOverlayStyle(
    statusBarColor: AppColors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: AppColors.cave,
    systemNavigationBarIconBrightness: Brightness.light,
  );
}
