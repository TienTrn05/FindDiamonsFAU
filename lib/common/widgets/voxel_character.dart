import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/theme/character_palette.dart';

class VoxelCharacter extends StatefulWidget {
  const VoxelCharacter({
    super.key,
    this.palette = 'steve',
    this.walking = false,
    this.headOnly = false,
  });
  final String palette;
  final bool walking;
  final bool headOnly;

  @override
  State<VoxelCharacter> createState() => _VoxelCharacterState();
}

class _VoxelCharacterState extends State<VoxelCharacter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    _updateAnimation();
  }

  @override
  void didUpdateWidget(VoxelCharacter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.walking != oldWidget.walking) _updateAnimation();
  }

  void _updateAnimation() {
    if (widget.walking) {
      _animation.repeat(reverse: true);
    } else {
      _animation.stop();
      _animation.value = .5;
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _animation,
    builder: (_, _) => CustomPaint(
      painter: _CharacterPainter(
        widget.palette,
        widget.headOnly,
        widget.walking ? (_animation.value - .5) * 2 : 0,
      ),
      child: const SizedBox.expand(),
    ),
  );
}

class _CharacterPainter extends CustomPainter {
  const _CharacterPainter(this.palette, this.headOnly, this.stride);
  final String palette;
  final bool headOnly;
  final double stride;

  @override
  void paint(Canvas canvas, Size size) {
    final colors = CharacterPalette.of(palette);
    final scale = math.min(
      size.width / (headOnly ? 8 : 16),
      size.height / (headOnly ? 8 : 32),
    );
    canvas.save();
    canvas.translate(
      (size.width - scale * (headOnly ? 8 : 16)) / 2,
      (size.height - scale * (headOnly ? 8 : 32)) / 2,
    );
    canvas.scale(scale);
    void block(double x, double y, double w, double h, Color color) =>
        canvas.drawRect(
          Rect.fromLTWH(x, y, w, h),
          Paint()
            ..color = color
            ..isAntiAlias = false,
        );
    final x = headOnly ? 0.0 : 4.0;
    block(x, 0, 8, 8, colors.skin);
    block(x, 0, 8, 2, colors.hair);
    block(x, 2, 1, 2, colors.hair);
    block(x + 7, 2, 1, 2, colors.hair);
    block(x + 1, 4, 2, 1, CharacterPalette.eyeWhite);
    block(x + 5, 4, 2, 1, CharacterPalette.eyeWhite);
    block(x + 2, 4, 1, 1, colors.eyes);
    block(x + 5, 4, 1, 1, colors.eyes);
    block(x + 3, 5, 2, 1, Color.lerp(colors.skin, colors.hair, .2)!);
    block(x + 2, 6, 4, 2, colors.hair);
    block(x + 3, 6, 2, 1, colors.skin);
    if (!headOnly) {
      block(4, 8, 8, 12, colors.shirt);
      block(7, 8, 2, 1, colors.skin);
      block(0, 8, 4, 4, colors.shirt);
      block(12, 8, 4, 4, colors.shirt);
      block(0, 12 + stride, 4, 8, colors.skin);
      block(12, 12 - stride, 4, 8, colors.skin);
      block(4, 20, 4, 12 - stride, colors.trousers);
      block(8, 20, 4, 12 + stride, colors.trousers);
      block(4, 30 - stride, 4, 2, CharacterPalette.shoes);
      block(8, 30 + stride, 4, 2, CharacterPalette.shoes);
      if (palette == 'knight' || palette == 'panda') {
        block(4, 18, 8, 1, CharacterPalette.gold);
        block(6, 11, 4, 3, palette == 'knight' ? colors.hair : colors.trousers);
      }
      if (palette == 'neon') {
        block(6, 9, 4, 10, colors.hair);
        block(7, 12, 2, 2, colors.shirt);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CharacterPainter oldDelegate) =>
      palette != oldDelegate.palette ||
      headOnly != oldDelegate.headOnly ||
      stride != oldDelegate.stride;
}
