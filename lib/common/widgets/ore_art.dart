import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/ore_palette.dart';

enum Ore { diamond, copper, coal, lapis, redstone, stone, gold, emerald }

class OreIcon extends StatelessWidget {
  const OreIcon({super.key, this.ore = Ore.diamond, this.size = 48});
  final Ore ore;
  final double size;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _OrePainter(ore));
}

class OreBackground extends StatelessWidget {
  const OreBackground({
    super.key,
    required this.child,
    this.diamondOnly = false,
  });
  final Widget child;
  final bool diamondOnly;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const ColoredBox(color: AppColors.surface),
      Positioned.fill(
        child: CustomPaint(painter: _PatternPainter(diamondOnly)),
      ),
      child,
    ],
  );
}

class _PatternPainter extends CustomPainter {
  const _PatternPainter(this.diamondOnly);
  final bool diamondOnly;
  @override
  void paint(Canvas canvas, Size size) {
    final tile = math.min(size.width / 3.2, 155.0);
    const pattern = [
      [Ore.diamond, Ore.copper, Ore.coal, Ore.lapis],
      [Ore.redstone, Ore.stone, Ore.diamond, Ore.copper],
      [Ore.gold, Ore.emerald, Ore.redstone, Ore.stone],
      [Ore.coal, Ore.lapis, Ore.gold, Ore.emerald],
    ];
    canvas.saveLayer(
      Offset.zero & size,
      Paint()..color = OrePalette.patternOpacity,
    );
    for (var row = 0; row < (size.height / tile).ceil() + 1; row++) {
      for (var col = 0; col < (size.width / tile).ceil() + 1; col++) {
        canvas.save();
        canvas.translate(col * tile - tile * .10, row * tile - tile * .04);
        _OrePainter(
          diamondOnly ? Ore.diamond : pattern[row % 4][col % 4],
        ).paint(canvas, Size.square(tile * .97));
        canvas.restore();
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PatternPainter oldDelegate) =>
      diamondOnly != oldDelegate.diamondOnly;
}

class _OrePainter extends CustomPainter {
  const _OrePainter(this.ore);
  final Ore ore;

  static const colors = [
    OrePalette.diamond,
    OrePalette.copper,
    OrePalette.coal,
    OrePalette.lapis,
    OrePalette.redstone,
    OrePalette.stone,
    OrePalette.gold,
    OrePalette.emerald,
  ];

  void polygon(Canvas canvas, List<Offset> points, Color color) {
    final path = Path()..addPolygon(points, true);
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..isAntiAlias = false,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 32, size.height / 32);
    const outline = [
      Offset(15, 1),
      Offset(18, 1),
      Offset(18, 2),
      Offset(22, 2),
      Offset(22, 4),
      Offset(26, 4),
      Offset(26, 6),
      Offset(29, 6),
      Offset(29, 8),
      Offset(31, 8),
      Offset(31, 24),
      Offset(29, 24),
      Offset(29, 26),
      Offset(25, 26),
      Offset(25, 28),
      Offset(21, 28),
      Offset(21, 30),
      Offset(18, 30),
      Offset(18, 31),
      Offset(15, 31),
      Offset(15, 30),
      Offset(12, 30),
      Offset(12, 28),
      Offset(8, 28),
      Offset(8, 26),
      Offset(4, 26),
      Offset(4, 24),
      Offset(1, 24),
      Offset(1, 9),
      Offset(3, 9),
      Offset(3, 7),
      Offset(6, 7),
      Offset(6, 5),
      Offset(10, 5),
      Offset(10, 3),
      Offset(15, 3),
    ];
    polygon(canvas, outline, OrePalette.outline);
    final clip = Path()..addPolygon(outline, true);
    canvas.save();
    canvas.clipPath(clip);
    polygon(canvas, [
      const Offset(2, 9),
      const Offset(16, 2),
      const Offset(30, 9),
      const Offset(16, 17),
    ], OrePalette.topFace);
    polygon(canvas, [
      const Offset(2, 10),
      const Offset(16, 17),
      const Offset(16, 30),
      const Offset(2, 23),
    ], OrePalette.leftFace);
    polygon(canvas, [
      const Offset(16, 17),
      const Offset(30, 10),
      const Offset(30, 23),
      const Offset(16, 30),
    ], OrePalette.rightFace);
    final random = math.Random(ore.index + 27);
    for (var i = 0; i < 65; i++) {
      final x = random.nextInt(29) + 2.0;
      final y = random.nextInt(29) + 2.0;
      canvas.drawRect(
        Rect.fromLTWH(
          x,
          y,
          2 + random.nextInt(3).toDouble(),
          1 + random.nextInt(3).toDouble(),
        ),
        Paint()
          ..color = [
            OrePalette.textureLight,
            OrePalette.textureDark,
            OrePalette.textureHighlight,
          ][i % 3],
      );
    }
    if (ore != Ore.stone) {
      final color = colors[ore.index];
      const flecks = [
        Offset(8, 6),
        Offset(18, 5),
        Offset(25, 9),
        Offset(5, 13),
        Offset(25, 18),
        Offset(20, 25),
        Offset(9, 23),
        Offset(13, 11),
      ];
      for (final p in flecks) {
        canvas.drawRect(
          Rect.fromLTWH(p.dx, p.dy, 3, 3),
          Paint()..color = color,
        );
        canvas.drawRect(
          Rect.fromLTWH(p.dx, p.dy, 2, 1),
          Paint()..color = Color.lerp(color, AppColors.surface, .65)!,
        );
        canvas.drawRect(
          Rect.fromLTWH(p.dx + 2, p.dy + 2, 1, 2),
          Paint()..color = Color.lerp(color, AppColors.text, .2)!,
        );
      }
      if (ore == Ore.diamond || ore == Ore.copper) {
        polygon(canvas, [
          const Offset(11, 14),
          const Offset(15, 11),
          const Offset(20, 14),
          const Offset(20, 17),
          const Offset(15, 23),
          const Offset(11, 18),
        ], Color.lerp(color, AppColors.surface, .35)!);
        polygon(canvas, [
          const Offset(12, 14),
          const Offset(15, 13),
          const Offset(18, 15),
          const Offset(15, 19),
        ], OrePalette.gemHighlight);
        canvas.drawRect(
          const Rect.fromLTWH(14, 14, 2, 3),
          Paint()..color = AppColors.surface,
        );
      }
    }
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(_OrePainter oldDelegate) => ore != oldDelegate.ore;
}
