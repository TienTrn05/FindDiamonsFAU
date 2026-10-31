import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../../common/widgets/app_text.dart';
import '../../../common/widgets/mining_art.dart';
import '../../../core/theme/mining_style.dart';

class DashboardHeader extends StatelessWidget {
  const DashboardHeader({
    super.key,
    required this.onSettings,
    this.backgroundAsset,
  });

  final VoidCallback onSettings;

  /// Optional cave artwork behind the logo.
  /// Leave null to use the parent page's background.
  final String? backgroundAsset;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          key: const ValueKey('dashboard-header'),
          clipBehavior: Clip.hardEdge,
          children: [
            // Background artwork (optional).
            if (backgroundAsset != null)
              Positioned.fill(
                child: Image.asset(backgroundAsset!, fit: BoxFit.cover),
              ),

            // Dark atmospheric shading.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.25, -0.25),
                    radius: 1.15,
                    colors: [
                      MiningStyle.cyan.withValues(alpha: 0.14),
                      const Color(0xFF00131F).withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Wordmark is independent of the settings button.
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 12,
                  right: 54,
                  top: 4,
                  bottom: 2,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      key: const ValueKey('dashboard-wordmark'),
                      width: 285,
                      height: 164,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // ORE: bright stone lettering.
                          Positioned(
                            left: 14,
                            top: 6,
                            child: _word('ORE', 68, const [
                              Color(0xFFFFFFFF),
                              Color(0xFFE4EBF7),
                              Color(0xFF8294AC),
                            ]),
                          ),

                          // SCOUT: diamond cyan lettering.
                          Positioned(
                            left: 14,
                            top: 61,
                            child: _word('SCOUT', 70, const [
                              Color(0xFFB8FFFF),
                              Color(0xFF19F4FF),
                              Color(0xFF0088C3),
                            ]),
                          ),

                          // Pixel pickaxe next to the wordmark.
                          const Positioned(
                            right: 8,
                            top: 9,
                            child: CustomPaint(
                              size: Size(58, 58),
                              painter: _PixelPickaxePainter(),
                            ),
                          ),

                          // Diamond particles.
                          const Positioned(
                            left: 225,
                            top: 0,
                            child: MiningArt(MiningArtKind.gem, size: 20),
                          ),

                          const Positioned(
                            left: 252,
                            top: 60,
                            child: MiningArt(MiningArtKind.gem, size: 18),
                          ),

                          const Positioned(
                            left: 2,
                            top: 94,
                            child: MiningArt(MiningArtKind.gem, size: 15),
                          ),

                          const Positioned(
                            left: 250,
                            top: 116,
                            child: Icon(
                              Icons.add,
                              size: 12,
                              color: Color(0xFF4DF6FF),
                            ),
                          ),

                          // Tagline.
                          Positioned(
                            left: 14,
                            right: 0,
                            top: 143,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: AppText(
                                'FIND ORES. EXPLORE MORE.',
                                style: MiningStyle.label.copyWith(
                                  fontSize: 12,
                                  letterSpacing: 0.4,
                                  color: const Color(0xFFEAF7FF),
                                  shadows: const [
                                    Shadow(
                                      color: Color(0xFF020810),
                                      offset: Offset(1, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Actual working settings control.
            Positioned(
              right: 10,
              top: 10,
              child: Material(
                key: const ValueKey('dashboard-settings'),
                color: const Color(0xFF283543),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: const BorderSide(color: Color(0xFF718092), width: 2),
                ),
                elevation: 3,
                child: InkWell(
                  onTap: onSettings,
                  borderRadius: BorderRadius.circular(5),
                  child: const SizedBox(
                    width: 34,
                    height: 34,
                    child: Icon(
                      Icons.settings,
                      color: Color(0xFFE9F2F8),
                      size: 21,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _word(String text, double size, List<Color> colors) {
    final style = TextStyle(
      fontFamily: 'PixelifySans',
      fontSize: size,
      fontWeight: FontWeight.w700,
      fontVariations: const [FontVariation('wght', 700)],
      letterSpacing: -1.5,
      height: 0.95,
    );

    Widget outline(double width, Color color) {
      return Text(
        text,
        textScaler: TextScaler.noScaling,
        style: style.copyWith(
          foreground: Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = width
            ..strokeJoin = StrokeJoin.bevel
            ..color = color,
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Hard offset for a Minecraft-like block extrusion.
        Transform.translate(
          offset: const Offset(3, 6),
          child: ExcludeSemantics(child: outline(7, const Color(0xFF020810))),
        ),

        ExcludeSemantics(child: outline(5, const Color(0xFF030B15))),

        ExcludeSemantics(
          child: Transform.translate(
            offset: const Offset(1, 3),
            child: outline(2, const Color(0xFF304456)),
          ),
        ),

        CustomPaint(
          foregroundPainter: _WordGradientPainter(text, style, colors),
          // Retain the paragraph's exact layout and accessible label. The
          // painter draws in local coordinates without a ShaderMask layer.
          child: Text(
            text,
            textScaler: TextScaler.noScaling,
            style: style.copyWith(color: Colors.transparent),
          ),
        ),
      ],
    );
  }
}

class _WordGradientPainter extends CustomPainter {
  const _WordGradientPainter(this.text, this.style, this.colors);
  final String text;
  final TextStyle style;
  final List<Color> colors;
  @override
  void paint(Canvas canvas, Size size) {
    final shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: colors,
      stops: const [0, .48, 1],
    ).createShader(Offset.zero & size);
    for (final stroke in [false, true]) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: style.copyWith(
            foreground: Paint()
              ..shader = shader
              ..style = stroke ? PaintingStyle.stroke : PaintingStyle.fill
              ..strokeWidth = 1.5
              ..strokeJoin = StrokeJoin.bevel,
          ),
        ),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
      )..layout();
      painter.paint(canvas, Offset.zero);
      painter.dispose();
    }
  }

  @override
  bool shouldRepaint(covariant _WordGradientPainter oldDelegate) =>
      text != oldDelegate.text ||
      style != oldDelegate.style ||
      !listEquals(colors, oldDelegate.colors);
}

/// Small pixel-art pickaxe drawn with rectangles and polygons.
/// Does not require any extra image assets.
class _PixelPickaxePainter extends CustomPainter {
  const _PixelPickaxePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();

    canvas.scale(size.width / 58, size.height / 58);

    final outline = Paint()..color = const Color(0xFF071019);

    final wood = Paint()..color = const Color(0xFF9E5F27);

    final woodLight = Paint()..color = const Color(0xFFE2A354);

    final metal = Paint()..color = const Color(0xFF00A6BA);

    final metalLight = Paint()..color = const Color(0xFF9AFFFF);

    Path polygon(List<Offset> points) {
      final p = Path()..moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        p.lineTo(point.dx, point.dy);
      }
      p.close();
      return p;
    }

    // Diagonal wooden handle.
    final handleOutline = polygon([
      const Offset(7, 50),
      const Offset(3, 46),
      const Offset(34, 15),
      const Offset(40, 21),
      const Offset(10, 52),
    ]);

    canvas.drawPath(handleOutline, outline);

    canvas.drawPath(
      polygon([
        const Offset(8, 46),
        const Offset(7, 43),
        const Offset(34, 16),
        const Offset(37, 20),
        const Offset(10, 48),
      ]),
      wood,
    );

    canvas.drawLine(
      const Offset(11, 43),
      const Offset(33, 21),
      woodLight..strokeWidth = 3,
    );

    // Pickaxe head.
    canvas.drawPath(
      polygon([
        const Offset(14, 14),
        const Offset(22, 7),
        const Offset(36, 5),
        const Offset(49, 10),
        const Offset(54, 17),
        const Offset(48, 20),
        const Offset(40, 15),
        const Offset(34, 15),
        const Offset(27, 23),
        const Offset(20, 19),
        const Offset(25, 13),
      ]),
      outline,
    );

    canvas.drawPath(
      polygon([
        const Offset(19, 13),
        const Offset(25, 9),
        const Offset(36, 8),
        const Offset(47, 12),
        const Offset(49, 15),
        const Offset(40, 12),
        const Offset(32, 12),
        const Offset(26, 19),
        const Offset(23, 17),
        const Offset(28, 11),
      ]),
      metal,
    );

    canvas.drawPath(
      polygon([
        const Offset(22, 11),
        const Offset(35, 7),
        const Offset(44, 10),
        const Offset(33, 10),
      ]),
      metalLight,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
