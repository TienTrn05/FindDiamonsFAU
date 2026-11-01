import 'package:flutter/material.dart';

import 'app_text_styles.dart';
import 'app_colors.dart';

/// Shared mining palette, backed by the application-wide semantic colors.
abstract final class MiningStyle {
  static const cyan = AppColors.primary;
  static const teal = AppColors.cavePanel;
  static const gold = AppColors.gold;
  static const amber = AppColors.goldPanel;
  static const green = AppColors.online;
  static const stone = AppColors.stone;
  static const edge = AppColors.stoneEdge;
  static const ink = AppColors.ink;
  static const muted = AppColors.inkMuted;
  static const steel = AppColors.steel;
  static const rankedAccents = [
    cyan,
    gold,
    AppColors.danger,
    green,
    Color(0xFFB967FF),
    AppColors.stone,
  ];
  static const serverAccents = [
    cyan,
    gold,
    AppColors.danger,
    green,
    Color(0xFFB967FF),
    Color(0xFF5F94FF),
    Color(0xFFFFA454),
    Color(0xFFFF66C4),
  ];
  static Color oreAccent(String id) => switch (id) {
    'gold' => gold,
    'redstone' => AppColors.danger,
    'emerald' => green,
    'netherite' => rankedAccents[4],
    'iron' => AppColors.stone,
    'copper' => const Color(0xFFFFA454),
    'coal' => const Color(0xFF9AAEC1),
    'lapis' => const Color(0xFF5F94FF),
    _ => cyan,
  };
  static const seedGreen = Color(0xFF2C842C);
  static const heading = TextStyle(
    fontFamily: AppFonts.body,
    fontWeight: FontWeight.w700,
    fontSize: 28,
    height: 1.12,
    color: Colors.white,
    shadows: [
      Shadow(color: Color(0xFF06111B), offset: Offset(0, 2)),
      Shadow(color: Colors.white, offset: Offset(.35, 0)),
    ],
  );
  static const cardTitle = TextStyle(
    fontFamily: AppFonts.body,
    fontWeight: FontWeight.w700,
    fontSize: 21,
    height: 1.15,
    color: ink,
    shadows: [Shadow(color: ink, offset: Offset(.3, 0))],
  );
  static const label = TextStyle(
    fontFamily: AppFonts.body,
    fontWeight: FontWeight.w700,
    fontSize: 14,
    height: 1.2,
    color: ink,
  );
  static const body = TextStyle(
    fontFamily: AppFonts.reading,
    fontSize: 14,
    height: 1.35,
    letterSpacing: .2,
    color: muted,
  );
}
