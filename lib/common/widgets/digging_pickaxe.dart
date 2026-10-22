import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/localization/app_translations.dart';
import '../../core/theme/app_colors.dart';

/// Pixel geometry animated with a ticker; no animated image or network asset.
class DiggingPickaxe extends StatefulWidget {
  const DiggingPickaxe({super.key});

  @override
  State<DiggingPickaxe> createState() => _DiggingPickaxeState();
}

class _DiggingPickaxeState extends State<DiggingPickaxe>
    with SingleTickerProviderStateMixin {
  late final AnimationController _swing = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _swing.stop();
      _swing.value = 0;
    } else if (!_swing.isAnimating) {
      _swing.repeat();
    }
  }

  @override
  void dispose() {
    _swing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.tr('Digging'),
    image: true,
    child: RepaintBoundary(
      child: CustomPaint(
        painter: _PickaxePainter(_swing),
        child: const SizedBox.expand(),
      ),
    ),
  );
}

class _PickaxePainter extends CustomPainter {
  _PickaxePainter(this.swing) : super(repaint: swing);
  final Animation<double> swing;

  @override
  void paint(Canvas canvas, Size size) {
    final phase = swing.value;
    final scale = math.min(size.width / 32, size.height / 27);
    final center = Offset(size.width / 2, size.height / 2);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);
    canvas.rotate(-math.pi / 4);
    canvas.translate(-9, -9);
    canvas.translate(16, 16);
    canvas.rotate(math.sin(phase * 2 * math.pi) * .24);
    canvas.translate(-16, -16);

    void block(double x, double y, double width, double height, Color color) =>
        canvas.drawRect(
          Rect.fromLTWH(x, y, width, height),
          Paint()
            ..color = color
            ..isAntiAlias = false,
        );

    for (var i = 0; i < 11; i++) {
      block(5 + i.toDouble(), 5 + i.toDouble(), 4, 4, AppColors.pickaxeOutline);
    }
    for (var i = 0; i < 11; i++) {
      block(
        6 + i.toDouble(),
        6 + i.toDouble(),
        2,
        2,
        i.isEven ? AppColors.pickaxeHandle : AppColors.pickaxeHandleDark,
      );
    }
    final outline = Path()
      ..addPolygon(const [
        Offset(1, 2),
        Offset(2, 1),
        Offset(12, 1),
        Offset(12, 2),
        Offset(13, 2),
        Offset(13, 4),
        Offset(10, 4),
        Offset(10, 5),
        Offset(6, 5),
        Offset(6, 6),
        Offset(5, 6),
        Offset(5, 10),
        Offset(4, 10),
        Offset(4, 13),
        Offset(2, 13),
        Offset(2, 12),
        Offset(1, 12),
      ], true);
    canvas.drawPath(
      outline,
      Paint()
        ..color = AppColors.pickaxeOutline
        ..isAntiAlias = false,
    );
    block(2, 2, 9, 2, AppColors.pickaxeHighlight);
    block(2, 3, 2, 8, AppColors.pickaxeHighlight);
    block(3, 3, 7, 1, AppColors.pickaxeSteel);
    block(3, 4, 2, 5, AppColors.pickaxeSteel);
    block(4, 4, 2, 2, AppColors.pickaxeHighlight);
    block(5, 5, 2, 2, AppColors.pickaxeSteel);
    canvas.restore();

    // Dust leaves the impact point during the downward part of each swing.
    if (phase > .48 && phase < .9) {
      final travel = (phase - .48) / .42;
      final paint = Paint()
        ..color = AppColors.pickaxeSteel.withValues(alpha: 1 - travel);
      for (var i = 0; i < 3; i++) {
        final origin = center + Offset(-8 * scale, 5 * scale);
        final point =
            origin +
            Offset(
              (-2 + i * 2) * travel * scale,
              (-3 * travel + 5 * travel * travel) * scale,
            );
        canvas.drawRect(
          Rect.fromCenter(
            center: point,
            width: scale * .65,
            height: scale * .65,
          ),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_PickaxePainter oldDelegate) => swing != oldDelegate.swing;
}
