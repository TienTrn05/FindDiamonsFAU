import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppFonts {
  static const body = 'Monocraft';
  static const fallback = ['Roboto'];
}

/// Reusable type styles. Feature widgets select styles instead of defining fonts.
abstract final class AppTextStyles {
  static const gameHeader = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 28,
    color: AppColors.onPrimary,
    height: 1.05,
  );
  static const fieldLabel = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    height: 1.15,
  );
  static const fieldValue = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const resultCoordinates = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
    fontFeatures: [FontFeature.tabularFigures()],
  );
  static const navigationLabel = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 14,
    height: 1.15,
  );
  static const itemTitle = TextStyle(fontFamily: AppFonts.body, fontSize: 19);
  static const historyCard = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
    fontFeatures: [FontFeature.tabularFigures()],
    height: 1.2,
  );
  static const serverTitle = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 14,
    fontWeight: FontWeight.w700,
  );
  static const serverCount = TextStyle(fontFamily: AppFonts.body, fontSize: 14);
  static const serverInfoTitle = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 21,
    fontWeight: FontWeight.w700,
    color: AppColors.onPrimary,
  );
  static const serverInfoAction = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.onPrimary,
  );
  static const serverInfoBody = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 14,
    height: 1.25,
    color: AppColors.text,
  );
  static const serverInfoTag = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 12,
    color: AppColors.text,
  );
  static const tag = TextStyle(fontFamily: AppFonts.body, fontSize: 10);
  static const rank = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    color: AppColors.onPrimary,
  );
  static const adAction = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 23,
    fontWeight: FontWeight.w800,
    color: AppColors.adAction,
  );
  static const body = TextStyle(fontFamily: AppFonts.body, fontSize: 15);
  static const helpHeading = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 18,
    height: 1.15,
    color: AppColors.text,
  );
  static const helpBody = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 14,
    height: 1.25,
    color: AppColors.textSecondary,
  );
  static const helpAction = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 16,
    color: AppColors.onPrimary,
  );
  static const helpQuestion = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 16,
    height: 1.2,
    color: AppColors.textMuted,
  );
  static const helpLink = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 14,
    color: AppColors.serverNavigation,
    decoration: TextDecoration.underline,
  );
  static const helpFooter = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 13,
    color: AppColors.helpFooter,
  );
  static const button = TextStyle(fontSize: 21);
  static const dialogTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );
  static const unlockTitle = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 1.15,
    color: AppColors.text,
  );
  static const dialogBody = TextStyle(
    fontSize: 14,
    color: AppColors.textSecondary,
    height: 1.45,
  );
  static const caption = TextStyle(fontSize: 10, color: AppColors.textMuted);
  static const oreStatus = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 13,
    height: 1.3,
  );
  static const oreStamp = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    color: AppColors.oreStampInk,
    height: 1.1,
  );
  static const badge = TextStyle(
    color: AppColors.onPrimary,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );
  static const loading = TextStyle(fontFamily: AppFonts.body, fontSize: 34);
  static const title = TextStyle(fontFamily: AppFonts.body, fontSize: 28);
  static const pixelButton = TextStyle(fontFamily: AppFonts.body, fontSize: 21);
  static const pixelButtonSmall = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 18,
  );
  static const pixelBody = TextStyle(fontFamily: AppFonts.body, fontSize: 15);
  static const pixelBodyLarge = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 16,
  );
  static const pixelCount = TextStyle(fontFamily: AppFonts.body, fontSize: 17);
  static const pixelLabel = TextStyle(fontFamily: AppFonts.body, fontSize: 14);
  static const pixelPrice = TextStyle(fontFamily: AppFonts.body, fontSize: 21);
  static const pixelField = TextStyle(fontFamily: AppFonts.body, fontSize: 20);
  static const pixelTitle = TextStyle(fontFamily: AppFonts.body, fontSize: 23);
  static const onPrimaryPixelBody = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 16,
    color: AppColors.onPrimary,
  );
  static const onPrimaryPixelPrice = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 18,
    color: AppColors.onPrimary,
  );
  static const onPrimaryPixelSubtitle = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 18,
    color: AppColors.onPrimary,
  );
  static const onPrimaryPixelField = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 20,
    color: AppColors.onPrimary,
  );
  static const sectionTitle = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 27,
    color: AppColors.primary,
  );
  static const link = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 19,
    color: AppColors.primary,
  );
  static const linkSmall = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 14,
    color: AppColors.primary,
  );
  static const tutorialTitle = TextStyle(
    fontFamily: AppFonts.body,
    fontSize: 52,
    height: 1.15,
  );
  static const tutorialBody = TextStyle(fontSize: 17, height: 1.22);
  static const tutorialBodyRelaxed = TextStyle(fontSize: 17, height: 1.3);
  static const tutorialBodyCompact = TextStyle(fontSize: 17, height: 1.2);
}
