import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_text.dart';

/// Shared pixel geometry for panels, cards and actions in the mining flow.
class PixelBorder extends OutlinedBorder {
  const PixelBorder({super.side = BorderSide.none, this.step = 6});
  final double step;

  @override
  PixelBorder copyWith({BorderSide? side}) =>
      PixelBorder(side: side ?? this.side, step: step);

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);
  @override
  ShapeBorder scale(double t) =>
      PixelBorder(side: side.scale(t), step: step * t);
  Path _path(Rect r) {
    final s = step.clamp(0.0, r.shortestSide / 4);
    return Path()..addPolygon([
      Offset(r.left + s, r.top),
      Offset(r.right - s, r.top),
      Offset(r.right - s, r.top + s),
      Offset(r.right, r.top + s),
      Offset(r.right, r.bottom - s),
      Offset(r.right - s, r.bottom - s),
      Offset(r.right - s, r.bottom),
      Offset(r.left + s, r.bottom),
      Offset(r.left + s, r.bottom - s),
      Offset(r.left, r.bottom - s),
      Offset(r.left, r.top + s),
      Offset(r.left + s, r.top + s),
    ], true);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) => _path(rect);
  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      _path(rect.deflate(side.width));
  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.solid) {
      canvas.drawPath(
        _path(rect.deflate(side.width / 2)),
        Paint()
          ..color = side.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = side.width,
      );
    }
  }
}

class MiningPanel extends StatelessWidget {
  const MiningPanel({
    super.key,
    required this.child,
    this.color = AppColors.surface,
    this.borderColor = AppColors.helpBorder,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.vivid = false,
    this.scenery = false,
    this.actionFinish = false,
  });
  final Widget child;
  final Color color;
  final Color borderColor;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool vivid;
  final bool scenery;
  final bool actionFinish;

  @override
  Widget build(BuildContext context) => Container(
    decoration: ShapeDecoration(
      color: color,
      shape: PixelBorder(side: BorderSide(color: borderColor, width: 2)),
      shadows: [
        if (vivid)
          BoxShadow(
            color: borderColor.withValues(alpha: .22),
            blurRadius: 16,
            spreadRadius: -3,
          ),
        BoxShadow(
          color: AppColors.cave.withValues(alpha: .6),
          offset: const Offset(0, 5),
          blurRadius: 2,
        ),
      ],
    ),
    child: Material(
      color: AppColors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: PixelBorder(side: BorderSide(color: borderColor, width: 2)),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(
                  color,
                  AppColors.onPrimary,
                  actionFinish
                      ? .33
                      : vivid
                      ? .20
                      : .10,
                )!,
                color,
                Color.lerp(color, AppColors.cave, vivid ? .18 : .08)!,
              ],
            ),
          ),
          child: !vivid && !scenery
              ? Padding(padding: padding, child: child)
              : Stack(
                  children: [
                    if (scenery)
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/help_cave.png',
                          opacity: const AlwaysStoppedAnimation(.21),
                          fit: BoxFit.cover,
                          alignment: Alignment.bottomCenter,
                        ),
                      ),
                    if (vivid)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            painter: _PixelFinish(
                              borderColor,
                              action: actionFinish,
                            ),
                          ),
                        ),
                      ),
                    Padding(padding: padding, child: child),
                  ],
                ),
        ),
      ),
    ),
  );
}

class MiningButton extends StatelessWidget {
  const MiningButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.color = AppColors.primary,
    this.foreground = AppColors.onPrimary,
    this.icon,
    this.trailing,
    this.semanticLabel,
    this.vivid = false,
    this.fontSize = 15,
    this.height = 52,
    this.art,
  });
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color foreground;
  final IconData? icon;
  final IconData? trailing;
  final String? semanticLabel;
  final bool vivid;
  final double fontSize;
  final double height;
  final Widget? art;
  Color get _ink =>
      foreground == AppColors.onPrimary && color == AppColors.primary
      ? AppColors.cave
      : foreground;
  @override
  Widget build(BuildContext context) => Opacity(
    opacity: onPressed == null ? .55 : 1,
    child: MiningPanel(
      vivid: vivid,
      actionFinish: vivid,
      color: color,
      borderColor: vivid
          ? Color.lerp(color, Colors.white, .35)!
          : Color.lerp(color, AppColors.cave, .4)!,
      padding: EdgeInsets.zero,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: _ink,
          minimumSize: Size(48, height),
          padding: EdgeInsets.symmetric(
            horizontal: label.isEmpty ? 6 : 12,
            vertical: vivid ? 8 : 12,
          ),
          shape: const PixelBorder(),
        ),
        child: Semantics(
          label: semanticLabel == null ? null : context.tr(semanticLabel!),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (art != null) ...[art!, const SizedBox(width: 12)],
              if (icon != null) ...[
                Icon(icon, size: vivid && label.isEmpty ? 21 : 25),
                if (label.isNotEmpty) const SizedBox(width: 9),
              ],
              if (label.isNotEmpty)
                Flexible(
                  child: AppText(
                    label,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.pixelButtonSmall.copyWith(
                      fontSize: fontSize,
                      color: _ink,
                      fontWeight: FontWeight.w700,
                      shadows: vivid
                          ? [
                              Shadow(color: _ink, offset: const Offset(.35, 0)),
                              Shadow(
                                color: Colors.black.withValues(alpha: .2),
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              if (trailing != null) ...[
                const SizedBox(width: 9),
                Icon(trailing, size: 24),
              ],
            ],
          ),
        ),
      ),
    ),
  );
}

class MiningBackground extends StatelessWidget {
  const MiningBackground({
    super.key,
    required this.child,
    this.asset = 'assets/images/help_cave.png',
    this.vivid = false,
    this.headerAsset,
    this.bottomOpacity = 1,
  });
  final Widget child;
  final String asset;
  final bool vivid;
  final String? headerAsset;
  final double bottomOpacity;
  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light.copyWith(
      systemNavigationBarColor: AppColors.cave,
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: Stack(
              fit: StackFit.expand,
              children: [
                const ColoredBox(color: AppColors.cave),
                Positioned.fill(
                  child: Image.asset(
                    asset,
                    fit: BoxFit.cover,
                    color: AppColors.cave.withValues(alpha: vivid ? .08 : .35),
                    colorBlendMode: BlendMode.srcATop,
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.cave.withValues(alpha: vivid ? .05 : 0),
                        AppColors.cave.withValues(alpha: bottomOpacity),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: -50,
                  right: -100,
                  child: Container(
                    width: 300,
                    height: 350,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: .18),
                          AppColors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                if (headerAsset != null)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: AspectRatio(
                      aspectRatio: 1.5,
                      child: ShaderMask(
                        blendMode: BlendMode.dstIn,
                        shaderCallback: (bounds) => const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white,
                            Colors.white,
                            Colors.transparent,
                          ],
                          stops: [0, .72, 1],
                        ).createShader(bounds),
                        child: Image.asset(headerAsset!, fit: BoxFit.cover),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        child,
      ],
    ),
  );
}

/// Crisp bevels, small mineral tiles and localized glints, clipped by PixelBorder.
class _PixelFinish extends CustomPainter {
  const _PixelFinish(this.edge, {this.action = false});
  final Color edge;
  final bool action;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..isAntiAlias = false;
    paint.color = Colors.white.withValues(alpha: .62);
    canvas.drawRect(Rect.fromLTWH(7, 3, size.width - 14, 3), paint);
    canvas.drawRect(Rect.fromLTWH(3, 7, 3, size.height - 14), paint);
    paint.color = Colors.black.withValues(alpha: .25);
    canvas.drawRect(
      Rect.fromLTWH(7, size.height - 6, size.width - 14, 3),
      paint,
    );
    canvas.drawRect(
      Rect.fromLTWH(size.width - 6, 7, 3, size.height - 14),
      paint,
    );
    for (var i = 0; i < 24; i++) {
      final x = ((i * 73 + 29) % 397) / 397 * size.width;
      final y = ((i * 47 + 13) % 149) / 149 * size.height;
      paint.color = (i.isEven ? Colors.white : edge).withValues(alpha: .055);
      canvas.drawRect(Rect.fromLTWH(x, y, i % 3 == 0 ? 13 : 6, 7), paint);
    }
    paint.shader =
        RadialGradient(
          colors: [
            Colors.white.withValues(alpha: .22),
            Colors.white.withValues(alpha: 0),
          ],
        ).createShader(
          Rect.fromCircle(center: Offset(size.width * .82, 12), radius: 80),
        );
    canvas.drawRect(Offset.zero & size, paint);
    if (action) {
      paint.shader = null;
      paint.color = Colors.white.withValues(alpha: .32);
      for (final point in [
        Offset(13, 13),
        Offset(size.width - 18, 11),
        Offset(20, size.height - 17),
        Offset(size.width - 23, size.height - 19),
      ]) {
        canvas.drawRect(Rect.fromLTWH(point.dx, point.dy, 5, 5), paint);
      }
      paint.color = Colors.white.withValues(alpha: .72);
      canvas.drawRect(const Rect.fromLTWH(8, 9, 3, 9), paint);
      canvas.drawRect(
        Rect.fromLTWH(size.width - 15, size.height - 10, 7, 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_PixelFinish oldDelegate) =>
      edge != oldDelegate.edge || action != oldDelegate.action;
}
