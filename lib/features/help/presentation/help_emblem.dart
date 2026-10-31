import 'package:flutter/material.dart';

import '../../../common/widgets/ore_art.dart';
import '../../../core/theme/app_colors.dart';

/// Small, code-native pixel illustrations for the support cards.
class HelpEmblem extends StatelessWidget {
  const HelpEmblem({super.key, required this.kind, this.size = 52});
  final String kind;
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: size,
      child: kind == 'coordinates'
          ? OreIcon(size: size)
          : CustomPaint(painter: _EmblemPainter(kind)),
    ),
  );
}

class _EmblemPainter extends CustomPainter {
  const _EmblemPainter(this.kind);
  final String kind;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 32, size.height / 32);
    void block(double x, double y, double w, double h, Color color) =>
        canvas.drawRect(
          Rect.fromLTWH(x, y, w, h),
          Paint()
            ..color = color
            ..isAntiAlias = false,
        );
    void polygon(List<Offset> points, Color color) => canvas.drawPath(
      Path()..addPolygon(points, true),
      Paint()
        ..color = color
        ..isAntiAlias = false,
    );
    final darkGold = Color.lerp(AppColors.gold, AppColors.goldPanel, .5)!;
    final lightGold = Color.lerp(AppColors.gold, AppColors.onPrimary, .4)!;
    if (kind == 'language') {
      polygon(const [
        Offset(16, 1),
        Offset(29, 8),
        Offset(29, 25),
        Offset(16, 32),
        Offset(3, 25),
        Offset(3, 8),
      ], AppColors.cave);
      polygon(const [
        Offset(16, 3),
        Offset(27, 9),
        Offset(16, 15),
        Offset(5, 9),
      ], AppColors.primary);
      polygon(const [
        Offset(5, 10),
        Offset(16, 16),
        Offset(16, 29),
        Offset(5, 23),
      ], AppColors.accent);
      polygon(const [
        Offset(17, 16),
        Offset(27, 10),
        Offset(27, 23),
        Offset(17, 29),
      ], AppColors.primary);
      block(9, 6, 9, 4, AppColors.worldGrassLight);
      block(18, 9, 6, 4, AppColors.worldGrass);
      block(6, 13, 5, 7, AppColors.worldGrass);
      block(10, 21, 5, 5, AppColors.worldGrassLight);
      block(20, 16, 5, 7, AppColors.worldGrass);
      block(17, 24, 4, 4, AppColors.worldGrassLight);
    } else if (kind == 'tutorial') {
      block(2, 5, 28, 25, AppColors.cave);
      block(3, 7, 26, 22, darkGold);
      polygon(const [
        Offset(4, 5),
        Offset(12, 3),
        Offset(16, 6),
        Offset(20, 3),
        Offset(28, 5),
        Offset(28, 25),
        Offset(20, 23),
        Offset(16, 26),
        Offset(12, 23),
        Offset(4, 25),
      ], lightGold);
      block(15, 6, 2, 20, darkGold);
      for (var y = 9.0; y < 22; y += 4) {
        block(6, y, 7, 1, darkGold);
        block(19, y, 7, 1, darkGold);
      }
    } else if (kind == 'privacy' || kind == 'safety') {
      polygon(const [
        Offset(4, 2),
        Offset(28, 2),
        Offset(28, 22),
        Offset(23, 28),
        Offset(16, 32),
        Offset(9, 28),
        Offset(4, 22),
      ], AppColors.cave);
      polygon(const [
        Offset(6, 3),
        Offset(26, 3),
        Offset(26, 21),
        Offset(21, 26),
        Offset(16, 29),
        Offset(11, 26),
        Offset(6, 21),
      ], AppColors.gold);
      polygon(const [
        Offset(9, 6),
        Offset(23, 6),
        Offset(23, 20),
        Offset(16, 26),
        Offset(9, 20),
      ], AppColors.accent);
      polygon(const [
        Offset(16, 9),
        Offset(21, 15),
        Offset(16, 22),
        Offset(11, 15),
      ], AppColors.primary);
      polygon(const [
        Offset(16, 9),
        Offset(16, 22),
        Offset(11, 15),
      ], AppColors.onPrimary);
    } else if (kind == 'seed') {
      polygon(const [
        Offset(16, 2),
        Offset(29, 9),
        Offset(16, 16),
        Offset(3, 9),
      ], AppColors.worldGrassLight);
      polygon(const [
        Offset(3, 10),
        Offset(16, 17),
        Offset(16, 30),
        Offset(3, 23),
      ], AppColors.worldEarth);
      polygon(const [
        Offset(17, 17),
        Offset(29, 10),
        Offset(29, 23),
        Offset(17, 30),
      ], AppColors.worldEarthShade);
      block(4, 11, 6, 5, AppColors.worldGrass);
      block(19, 16, 7, 4, AppColors.worldGrass);
      block(6, 20, 4, 3, AppColors.worldEarthShade);
      block(22, 22, 4, 3, AppColors.worldEarth);
    } else if (kind == 'pickaxe') {
      for (var i = 0.0; i < 6; i++) {
        block(7 + i * 3, 22 - i * 3, 4, 4, AppColors.cave);
        block(8 + i * 3, 23 - i * 3, 2, 3, AppColors.worldEarth);
      }
      block(11, 3, 16, 4, AppColors.cave);
      block(12, 3, 13, 2, AppColors.stoneLight);
      block(23, 5, 5, 13, AppColors.cave);
      block(24, 5, 3, 11, AppColors.stone);
      block(16, 6, 8, 3, AppColors.steel);
      block(23, 8, 2, 9, AppColors.steel);
    } else {
      block(3, 6, 26, 24, AppColors.cave);
      block(4, 5, 24, 23, darkGold);
      block(6, 3, 20, 22, AppColors.gold);
      block(7, 4, 18, 2, lightGold);
      block(6, 17, 20, 3, darkGold);
      block(16, 7, 9, 15, darkGold);
      if (kind == 'restore') {
        polygon(const [
          Offset(16, 1),
          Offset(24, 8),
          Offset(20, 16),
          Offset(12, 16),
          Offset(8, 8),
        ], AppColors.accent);
        polygon(const [
          Offset(16, 2),
          Offset(22, 8),
          Offset(19, 13),
          Offset(13, 13),
          Offset(10, 8),
        ], AppColors.primary);
        polygon(const [
          Offset(16, 2),
          Offset(16, 13),
          Offset(10, 8),
        ], AppColors.stoneLight);
        block(14, 19, 4, 5, lightGold);
      } else if (kind == 'versions') {
        for (var y = 7.0; y < 24; y += 6) {
          block(9, y, 14, 2, AppColors.goldPanel);
        }
        for (var x = 10.0; x < 24; x += 6) {
          block(x, 7, 2, 17, AppColors.goldPanel);
        }
      } else {
        block(11, 7, 10, 3, AppColors.goldPanel);
        block(19, 10, 3, 5, AppColors.goldPanel);
        block(15, 14, 6, 3, AppColors.goldPanel);
        block(14, 17, 3, 3, AppColors.goldPanel);
        block(14, 22, 3, 3, AppColors.goldPanel);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_EmblemPainter oldDelegate) => kind != oldDelegate.kind;
}
