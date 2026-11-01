import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../../core/network/app_image_cache.dart';
import '../../core/localization/app_translations.dart';

import '../../core/theme/character_palette.dart';

/// A solid block character with articulated limbs and a draggable camera.
class VoxelCharacter3D extends StatefulWidget {
  const VoxelCharacter3D({
    super.key,
    this.palette = 'steve',
    this.walking = false,
    this.skinTextureUrl,
  });

  final String palette;
  final bool walking;
  final Uri? skinTextureUrl;

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
  ui.Image? _skinTexture;
  ImageStream? _textureStream;
  ImageStreamListener? _textureListener;

  @override
  void initState() {
    super.initState();
    _loadTexture(widget.skinTextureUrl);
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
    if (widget.skinTextureUrl != oldWidget.skinTextureUrl) {
      _loadTexture(widget.skinTextureUrl);
    }
  }

  void _loadTexture(Uri? url) {
    final oldStream = _textureStream;
    final oldListener = _textureListener;
    if (oldStream != null && oldListener != null) {
      oldStream.removeListener(oldListener);
    }
    _textureStream = null;
    _textureListener = null;
    _skinTexture?.dispose();
    _skinTexture = null;
    if (url == null) {
      if (mounted) setState(() {});
      return;
    }

    final stream = AppNetworkImage(
      url.toString(),
    ).resolve(const ImageConfiguration());
    final listener = ImageStreamListener((info, _) {
      final image = info.image;
      final isMinecraftSkin =
          image.width >= 64 &&
          image.width % 64 == 0 &&
          (image.width == image.height || image.width == image.height * 2);
      final normalizedHeight = image.height * 64 ~/ image.width;
      final usable =
          isMinecraftSkin && (normalizedHeight == 64 || normalizedHeight == 32);
      final copy = usable ? image.clone() : null;
      info.dispose();
      if (!mounted) {
        copy?.dispose();
        return;
      }
      setState(() {
        _skinTexture?.dispose();
        _skinTexture = copy;
      });
    }, onError: (Object error, StackTrace? stackTrace) {});
    _textureStream = stream;
    _textureListener = listener;
    stream.addListener(listener);
  }

  @override
  void dispose() {
    final stream = _textureStream;
    final listener = _textureListener;
    if (stream != null && listener != null) stream.removeListener(listener);
    _skinTexture?.dispose();
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: context.tr('3D skin preview'),
    hint: context.tr(
      'Drag in any direction to rotate 360 degrees. Double tap to reset.',
    ),
    value: context.tr(
      '{horizontal} degrees horizontal, {vertical} degrees vertical',
      args: {
        'horizontal': '${(_yaw * 180 / math.pi).round() % 360}',
        'vertical': '${(_pitch * 180 / math.pi).round() % 360}',
      },
    ),
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
            texture: _skinTexture,
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
  _Face3(
    this.vertices,
    this.color, {
    this.textureRect,
    this.flipTextureX = false,
  });
  final List<_Point3> vertices;
  final Color color;
  final Rect? textureRect;
  final bool flipTextureX;
  final overlays = <_Face3>[];

  double get depth => vertices.fold(0.0, (sum, p) => sum + p.z) / 4;
}

class _Voxel3DPainter extends CustomPainter {
  const _Voxel3DPainter({
    required this.palette,
    required this.texture,
    required this.yaw,
    required this.pitch,
    required this.stride,
  });

  final String palette;
  final ui.Image? texture;
  final double yaw;
  final double pitch;
  final double stride;

  @override
  void paint(Canvas canvas, Size size) {
    final colors = CharacterPalette.of(palette);
    final skinTexture = texture;
    final faces = <_Face3>[];
    _Face3? frontSurface;

    _Face3? face(
      List<_Point3> vertices,
      Color color,
      double angle,
      double pivot, {
      bool overlay = false,
      Rect? textureRect,
      bool flipTextureX = false,
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
        textureRect: textureRect,
        flipTextureX: flipTextureX,
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
      List<Rect>? textureRegions,
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
        if (skinTexture == null && head && (side == 2 || side == 3)) {
          final midRight = _Point3(vertices[1].x, y + 4, vertices[1].z);
          final midLeft = _Point3(vertices[0].x, y + 4, vertices[0].z);
          face(
            [vertices[0], vertices[1], midRight, midLeft],
            colors.hair,
            angle,
            pivot,
            textureRect: textureRegions == null ? null : textureRegions[side],
          );
          face(
            [midLeft, midRight, vertices[2], vertices[3]],
            color,
            angle,
            pivot,
            textureRect: textureRegions == null ? null : textureRegions[side],
          );
        } else {
          final result = face(
            vertices,
            head && (side == 1 || side == 4) ? colors.hair : color,
            angle,
            pivot,
            textureRect: textureRegions == null ? null : textureRegions[side],
            flipTextureX: side == 1,
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

    if (skinTexture == null) {
      // Palette-based fallback for local demo skins.
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
    } else {
      final uvScale = skinTexture.width / 64;
      Rect uv(int x, int y, int width, int height) => Rect.fromLTWH(
        x * uvScale,
        y * uvScale,
        width * uvScale,
        height * uvScale,
      );
      List<Rect> faces({
        required Rect front,
        required Rect back,
        required Rect right,
        required Rect left,
        required Rect top,
        required Rect bottom,
      }) => [front, back, right, left, top, bottom];

      final headUv = faces(
        front: uv(8, 8, 8, 8),
        back: uv(24, 8, 8, 8),
        right: uv(0, 8, 8, 8),
        left: uv(16, 8, 8, 8),
        top: uv(8, 0, 8, 8),
        bottom: uv(16, 0, 8, 8),
      );
      final torsoUv = faces(
        front: uv(20, 20, 8, 12),
        back: uv(32, 20, 8, 12),
        right: uv(16, 20, 4, 12),
        left: uv(28, 20, 4, 12),
        top: uv(20, 16, 8, 4),
        bottom: uv(28, 16, 8, 4),
      );
      List<Rect> limbUv({
        required int startX,
        required int startY,
        required int width,
      }) => faces(
        front: uv(startX + 4, startY + 4, width, 12),
        back: uv(startX + 12, startY + 4, width, 12),
        right: uv(startX, startY + 4, 4, 12),
        left: uv(startX + 8, startY + 4, 4, 12),
        top: uv(startX + 4, startY, width, 4),
        bottom: uv(startX + 8, startY, width, 4),
      );

      box(-4, -16, -4, 8, 8, 8, Colors.white, textureRegions: headUv);
      box(
        -4.25,
        -16.25,
        -4.25,
        8.5,
        8.5,
        8.5,
        Colors.white,
        textureRegions: faces(
          front: uv(40, 8, 8, 8),
          back: uv(56, 8, 8, 8),
          right: uv(32, 8, 8, 8),
          left: uv(48, 8, 8, 8),
          top: uv(40, 0, 8, 8),
          bottom: uv(48, 0, 8, 8),
        ),
      );
      box(-4, -8, -2, 8, 12, 4, Colors.white, textureRegions: torsoUv);

      final isModern = skinTexture.height == skinTexture.width;
      if (isModern) {
        box(
          -4.15,
          -8.15,
          -2.15,
          8.3,
          12.3,
          4.3,
          Colors.white,
          textureRegions: faces(
            front: uv(20, 36, 8, 12),
            back: uv(32, 36, 8, 12),
            right: uv(16, 36, 4, 12),
            left: uv(28, 36, 4, 12),
            top: uv(20, 32, 8, 4),
            bottom: uv(28, 32, 8, 4),
          ),
        );
      }

      for (final arm in [(-8.0, stride), (4.0, -stride)]) {
        final isRightArm = arm.$1 < 0;
        final armUv = limbUv(
          startX: isRightArm || !isModern ? 40 : 32,
          startY: isRightArm || !isModern ? 16 : 48,
          width: 4,
        );
        box(
          arm.$1,
          -8,
          -2,
          4,
          12,
          4,
          Colors.white,
          angle: arm.$2,
          pivot: -8,
          textureRegions: armUv,
        );
        if (isModern) {
          final sleeveStartX = isRightArm ? 40 : 48;
          final sleeveStartY = isRightArm ? 32 : 48;
          box(
            arm.$1 - .15,
            -8.15,
            -2.15,
            4.3,
            12.3,
            4.3,
            Colors.white,
            angle: arm.$2,
            pivot: -8,
            textureRegions: limbUv(
              startX: sleeveStartX,
              startY: sleeveStartY,
              width: 4,
            ),
          );
        }
      }

      for (final leg in [(-4.0, -stride), (0.0, stride)]) {
        final isRightLeg = leg.$1 < 0;
        box(
          leg.$1,
          4,
          -2,
          4,
          12,
          4,
          Colors.white,
          angle: leg.$2,
          pivot: 4,
          textureRegions: limbUv(
            startX: isRightLeg || !isModern ? 0 : 16,
            startY: isRightLeg || !isModern ? 16 : 48,
            width: 4,
          ),
        );
        if (isModern) {
          box(
            leg.$1 - .15,
            3.85,
            -2.15,
            4.3,
            12.3,
            4.3,
            Colors.white,
            angle: leg.$2,
            pivot: 4,
            textureRegions: limbUv(
              startX: 0,
              startY: isRightLeg ? 32 : 48,
              width: 4,
            ),
          );
        }
      }
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
      path.close();
      final textureRect = face.textureRect;
      if (skinTexture != null && textureRect != null) {
        final first =
            center +
            Offset(face.vertices[0].x * scale, face.vertices[0].y * scale);
        final second =
            center +
            Offset(face.vertices[1].x * scale, face.vertices[1].y * scale);
        final fourth =
            center +
            Offset(face.vertices[3].x * scale, face.vertices[3].y * scale);
        final sourceLeft = face.flipTextureX
            ? textureRect.right
            : textureRect.left;
        final sourceRight = face.flipTextureX
            ? textureRect.left
            : textureRect.right;
        final sx = (second.dx - first.dx) / (sourceRight - sourceLeft);
        final sy = (second.dy - first.dy) / (sourceRight - sourceLeft);
        final tx = first.dx - sx * sourceLeft;
        final ty = first.dy - sy * sourceLeft;
        final vx = (fourth.dx - first.dx) / textureRect.height;
        final vy = (fourth.dy - first.dy) / textureRect.height;
        final translateX = tx - vx * textureRect.top;
        final translateY = ty - vy * textureRect.top;
        canvas.save();
        canvas.clipPath(path);
        canvas.transform(
          Float64List.fromList([
            sx,
            sy,
            0,
            0,
            vx,
            vy,
            0,
            0,
            0,
            0,
            1,
            0,
            translateX,
            translateY,
            0,
            1,
          ]),
        );
        canvas.drawImageRect(
          skinTexture,
          textureRect,
          textureRect,
          Paint()..filterQuality = FilterQuality.none,
        );
        canvas.restore();
      } else {
        canvas.drawPath(path, Paint()..color = face.color);
      }
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
      texture != oldDelegate.texture ||
      yaw != oldDelegate.yaw ||
      pitch != oldDelegate.pitch ||
      stride != oldDelegate.stride;
}
