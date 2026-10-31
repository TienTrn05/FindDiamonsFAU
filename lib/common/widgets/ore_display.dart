import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/mining_style.dart';
import 'ore_art.dart';

/// Mineral art, crystal pedestal and static glints for cards and the carousel.
class OreDisplay extends StatelessWidget {
  const OreDisplay({
    super.key,
    required this.id,
    this.size = 200,
    this.pin = false,
  });
  final String id;
  final double size;
  final bool pin;
  @override
  Widget build(BuildContext context) {
    final accent = MiningStyle.oreAccent(id);
    return SizedBox.square(
      dimension: size,
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [accent.withValues(alpha: .23), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _Crystals(accent))),
          Align(
            alignment: const Alignment(0, -.05),
            child: OreIcon(
              ore: Ore.values.firstWhere(
                (ore) => ore.name == id,
                orElse: () => Ore.diamond,
              ),
              mineralTint: accent,
              showCenterGem: false,
              size: size * .77,
            ),
          ),
          if (pin)
            Positioned(
              left: size * .34,
              top: size * .44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.location_on,
                    size: size * .24,
                    color: Colors.white,
                  ),
                  Icon(Icons.location_on, size: size * .205, color: accent),
                  Positioned(
                    top: size * .055,
                    child: Icon(
                      Icons.circle,
                      size: size * .065,
                      color: AppColors.cave,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Crystals extends CustomPainter {
  const _Crystals(this.color);
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    void polygon(List<Offset> points, Color ink) {
      paint.color = ink;
      canvas.drawPath(Path()..addPolygon(points, true), paint);
    }

    final w = size.width;
    final h = size.height;
    polygon([
      Offset(w * .1, h * .81),
      Offset(w * .5, h * .7),
      Offset(w * .9, h * .81),
      Offset(w * .5, h * .96),
    ], AppColors.helpRaised);
    polygon([
      Offset(w * .1, h * .81),
      Offset(w * .5, h * .96),
      Offset(w * .5, h),
      Offset(w * .1, h * .86),
    ], AppColors.cave);
    polygon([
      Offset(w * .5, h * .96),
      Offset(w * .9, h * .81),
      Offset(w * .9, h * .86),
      Offset(w * .5, h),
    ], AppColors.helpSurface);
    for (final base in [.14, .83]) {
      for (var j = 0; j < 3; j++) {
        final x = w * (base + (j - 1) * .035);
        final y = h * .84;
        final length = h * (j == 1 ? .17 : .12);
        polygon([
          Offset(x, y - length),
          Offset(x + w * .025, y - length + w * .025),
          Offset(x + w * .02, y),
          Offset(x - w * .018, y),
          Offset(x - w * .025, y - length + w * .025),
        ], color);
        polygon([
          Offset(x, y - length),
          Offset(x + w * .025, y - length + w * .025),
          Offset(x, y - length + w * .035),
          Offset(x - w * .025, y - length + w * .025),
        ], Colors.white.withValues(alpha: .8));
        polygon([
          Offset(x, y - length + w * .035),
          Offset(x + w * .025, y - length + w * .025),
          Offset(x + w * .02, y),
          Offset(x, y),
        ], Color.lerp(color, AppColors.cave, .35)!);
      }
    }
    for (var i = 0; i < 9; i++) {
      final x = w * (.08 + ((i * 37) % 83) / 100);
      final y = h * (.08 + ((i * 23) % 65) / 100);
      final r = math.max(1.0, w * (i.isEven ? .014 : .008));
      paint.color = i.isEven ? color : Colors.white;
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: r, height: r * 3),
        paint,
      );
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, y), width: r * 3, height: r),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_Crystals oldDelegate) => oldDelegate.color != color;
}
