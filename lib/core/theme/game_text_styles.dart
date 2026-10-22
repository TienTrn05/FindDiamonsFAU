import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text_styles.dart';
import 'game_palette.dart';

/// Typography inside the reference game artwork, separate from app controls.
abstract final class GameTextStyles {
  static const helpDebug = TextStyle(
    fontFamily: AppFonts.pixel,
    fontSize: 10,
    color: AppColors.onPrimary,
    height: 1.25,
    shadows: [Shadow(color: AppColors.text, blurRadius: 2)],
  );
  static const settings = TextStyle(
    fontFamily: AppFonts.pixel,
    fontSize: 8,
    color: GamePalette.settingsText,
  );
  static const toolbar = TextStyle(color: GamePalette.toolbarText);
  static const control = TextStyle(color: GamePalette.controlText);
  static const input = TextStyle(color: GamePalette.inputText);
  static const callout = TextStyle(
    fontSize: 29,
    fontWeight: FontWeight.w800,
    color: AppColors.onPrimary,
    height: 1.4,
  );
  static const highlightCallout = TextStyle(
    fontSize: 31,
    fontWeight: FontWeight.w900,
    height: 1.25,
    color: GamePalette.highlight,
  );
  static TextStyle get outlinedCallout => TextStyle(
    fontSize: 31,
    fontWeight: FontWeight.w900,
    height: 1.25,
    foreground: Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = AppColors.text,
  );
}
