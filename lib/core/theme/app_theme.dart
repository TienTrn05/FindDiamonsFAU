import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_spacing.dart';
import '../responsive/app_layout.dart';

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
  static ThemeData get light => ThemeData(
    fontFamily: AppFonts.body,
    fontFamilyFallback: AppFonts.fallback,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    scaffoldBackgroundColor: AppColors.surface,
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.permissionAction,
        minimumSize: const Size.fromHeight(AppLayout.permissionButtonMinHeight),
        textStyle: AppTextStyles.body,
      ),
    ),
    useMaterial3: true,
  );

  static const systemUi = SystemUiOverlayStyle(
    statusBarColor: AppColors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: AppColors.surface,
    systemNavigationBarIconBrightness: Brightness.dark,
  );
}
