import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../core/localization/app_translations.dart';

import '../../core/theme/character_palette.dart';

/// A solid block character with articulated limbs and a draggable camera.
class VoxelCharacter3D extends StatefulWidget {
  const VoxelCharacter3D({
    super.key,
    this.palette = 'steve',
    this.walking = false,
  });

  final String palette;
  final bool walking;

  @override
  State<VoxelCharacter3D> createState() => _VoxelCharacter3DState();
}

class _VoxelCharacter3DState extends State<VoxelCharacter3D>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  double _yaw = -.35;
  double _pitch = -.12;

  @override
  void initState() {
    super.initState();
    if (widget.walking) _animation.repeat();
  }

  @override
  void didUpdateWidget(VoxelCharacter3D oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.walking != oldWidget.walking) {
      if (widget.walking) {
        _animation.repeat();
      } else {
        _animation.stop();
      }
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.tr('3D skin preview'),
    hint: context.tr(
      'Drag in any direction to rotate 360 degrees. Double tap to reset.',
    ),
    value:
        '${(_yaw * 180 / math.pi).round() % 360} degrees horizontal, '
        '${(_pitch * 180 / math.pi).round() % 360} degrees vertical',
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanUpdate: (details) => setState(() {
        _yaw = (_yaw + details.delta.dx * .015) % (2 * math.pi);
        _pitch = (_pitch + details.delta.dy * .015) % (2 * math.pi);
      }),
      onDoubleTap: () => setState(() {
        _yaw = -.35;
        _pitch = -.12;
      }),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) => CustomPaint(
          painter: _Voxel3DPainter(
            palette: widget.palette,
            yaw: _yaw,
            pitch: _pitch,
            stride: widget.walking
                ? math.sin(_animation.value * 2 * math.pi) * .65
                : 0,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    ),
  );
}

class _Point3 {
  const _Point3(this.x, this.y, this.z);
  final double x;
  final double y;
  final double z;

  _Point3 rotateX(double angle, {double pivotY = 0}) {
    final dy = y - pivotY;
    return _Point3(
      x,
      pivotY + dy * math.cos(angle) - z * math.sin(angle),
      dy * math.sin(angle) + z * math.cos(angle),
    );
  }

  _Point3 rotateY(double angle) => _Point3(
    x * math.cos(angle) + z * math.sin(angle),
    y,
    -x * math.sin(angle) + z * math.cos(angle),
  );
}

class _Face3 {
  _Face3(this.vertices, this.color);
  final List<_Point3> vertices;
  final Color color;
  final overlays = <_Face3>[];

  double get depth => vertices.fold(0.0, (sum, p) => sum + p.z) / 4;
}

class _Voxel3DPainter extends CustomPainter {
  const _Voxel3DPainter({
    required this.palette,
    required this.yaw,
    required this.pitch,
    required this.stride,
  });

  final String palette;
  final double yaw;
  final double pitch;
  final double stride;

  @override
  void paint(Canvas canvas, Size size) {
    final colors = CharacterPalette.of(palette);
    final faces = <_Face3>[];
    _Face3? frontSurface;

    _Face3? face(
      List<_Point3> vertices,
      Color color,
      double angle,
      double pivot, {
      bool overlay = false,
    }) {
      final points = vertices
          .map(
            (p) => p.rotateX(angle, pivotY: pivot).rotateY(yaw).rotateX(pitch),
          )
          .toList();
      // Outward-facing winding allows hidden surfaces to be culled.
      final a = points[0];
      final b = points[1];
      final c = points[2];
      final nx = (b.y - a.y) * (c.z - a.z) - (b.z - a.z) * (c.y - a.y);
      final ny = (b.z - a.z) * (c.x - a.x) - (b.x - a.x) * (c.z - a.z);
      final nz = (b.x - a.x) * (c.y - a.y) - (b.y - a.y) * (c.x - a.x);
      if (nz <= 0) return null;
      final length = math.sqrt(nx * nx + ny * ny + nz * nz);
      final light = ((-nx - ny + 2 * nz) / (length * math.sqrt(6))).clamp(
        0.0,
        1.0,
      );
      final result = _Face3(
        points,
        Color.lerp(Colors.black, color, .60 + .40 * light)!,
      );
      if (overlay) {
        frontSurface?.overlays.add(result);
      } else {
        faces.add(result);
      }
      return result;
    }

    void box(
      double x,
      double y,
      double z,
      double w,
      double h,
      double d,
      Color color, {
      double angle = 0,
      double pivot = 0,
      bool head = false,
    }) {
      final p = [
        _Point3(x, y, z),
        _Point3(x + w, y, z),
        _Point3(x + w, y + h, z),
        _Point3(x, y + h, z),
        _Point3(x, y, z + d),
        _Point3(x + w, y, z + d),
        _Point3(x + w, y + h, z + d),
        _Point3(x, y + h, z + d),
      ];
      const sides = [
        [4, 5, 6, 7],
        [1, 0, 3, 2],
        [0, 4, 7, 3],
        [5, 1, 2, 6],
        [0, 1, 5, 4],
        [7, 6, 2, 3],
      ];
      for (var side = 0; side < sides.length; side++) {
        final vertices = [for (final i in sides[side]) p[i]];
        if (head && (side == 2 || side == 3)) {
          final midRight = _Point3(vertices[1].x, y + 4, vertices[1].z);
          final midLeft = _Point3(vertices[0].x, y + 4, vertices[0].z);
          face(
            [vertices[0], vertices[1], midRight, midLeft],
            colors.hair,
            angle,
            pivot,
          );
          face(
            [midLeft, midRight, vertices[2], vertices[3]],
            color,
            angle,
            pivot,
          );
        } else {
          final result = face(
            vertices,
            head && (side == 1 || side == 4) ? colors.hair : color,
            angle,
            pivot,
          );
          if (side == 0) frontSurface = result;
        }
      }
    }

    void front(double x, double y, double w, double h, double z, Color color) {
      face(
        [
          _Point3(x, y, z),
          _Point3(x + w, y, z),
          _Point3(x + w, y + h, z),
          _Point3(x, y + h, z),
        ],
        color,
        0,
        0,
        overlay: true,
      );
    }

    // Head: solid hair at the back and top, with pixel features on the face.
    box(-4, -16, -4, 8, 8, 8, colors.skin, head: true);
    front(-4, -16, 8, 2, 4.02, colors.hair);
    front(-4, -14, 1, 2, 4.02, colors.hair);
    front(3, -14, 1, 2, 4.02, colors.hair);
    front(-3, -12, 2, 1, 4.02, CharacterPalette.eyeWhite);
    front(1, -12, 2, 1, 4.02, CharacterPalette.eyeWhite);
    front(-2, -12, 1, 1, 4.03, colors.eyes);
    front(1, -12, 1, 1, 4.03, colors.eyes);
    front(-1, -11, 2, 1, 4.02, Color.lerp(colors.skin, colors.hair, .2)!);
    front(-2, -10, 4, 2, 4.02, colors.hair);
    front(-1, -10, 2, 1, 4.03, colors.skin);

    box(-4, -8, -2, 8, 12, 4, colors.shirt);
    front(-1, -8, 2, 1, 2.02, colors.skin);
    if (palette == 'knight' || palette == 'panda') {
      front(-4, 2, 8, 1, 2.02, CharacterPalette.gold);
      front(
        -2,
        -5,
        4,
        3,
        2.02,
        palette == 'knight' ? colors.hair : colors.trousers,
      );
    }
    if (palette == 'neon') {
      front(-2, -7, 4, 10, 2.02, colors.hair);
      front(-1, -4, 2, 2, 2.03, colors.shirt);
    }
    for (final arm in [(-8.0, stride), (4.0, -stride)]) {
      box(arm.$1, -8, -2, 4, 4, 4, colors.shirt, angle: arm.$2, pivot: -8);
      box(arm.$1, -4, -2, 4, 8, 4, colors.skin, angle: arm.$2, pivot: -8);
    }
    for (final leg in [(-4.0, -stride), (0.0, stride)]) {
      box(leg.$1, 4, -2, 4, 10, 4, colors.trousers, angle: leg.$2, pivot: 4);
      box(
        leg.$1,
        14,
        -2,
        4,
        2,
        4,
        CharacterPalette.shoes,
        angle: leg.$2,
        pivot: 4,
      );
    }

    // Orthographic projection preserves the block proportions at every angle.
    final scale = math.min(size.width / 26, size.height / 39);
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, 17.5 * scale),
        width: 15 * scale,
        height: 2 * scale,
      ),
      Paint()..color = CharacterPalette.outline.withValues(alpha: .12),
    );
    faces.sort((a, b) => a.depth.compareTo(b.depth));
    void drawFace(_Face3 face) {
      final path = Path();
      for (var i = 0; i < face.vertices.length; i++) {
        final p = face.vertices[i];
        final point = center + Offset(p.x * scale, p.y * scale);
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path..close(), Paint()..color = face.color);
      for (final overlay in face.overlays) {
        drawFace(overlay);
      }
    }

    for (final face in faces) {
      drawFace(face);
    }
  }

  @override
  bool shouldRepaint(_Voxel3DPainter oldDelegate) =>
      palette != oldDelegate.palette ||
      yaw != oldDelegate.yaw ||
      pitch != oldDelegate.pitch ||
      stride != oldDelegate.stride;
}
