import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'voxel_character.dart';

/// Shows the face and hat layer of a Minecraft skin instead of the full sheet.
class SkinHead extends StatefulWidget {
  const SkinHead({super.key, this.palette = 'steve', this.texture});

  final String palette;
  final ImageProvider? texture;

  @override
  State<SkinHead> createState() => _SkinHeadState();
}

class _SkinHeadState extends State<SkinHead> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ui.Image? _image;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadTexture();
  }

  @override
  void didUpdateWidget(covariant SkinHead oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.texture != oldWidget.texture) _loadTexture();
  }

  void _clearTexture() {
    final listener = _listener;
    if (listener != null) _stream?.removeListener(listener);
    _stream = null;
    _listener = null;
    _image?.dispose();
    _image = null;
  }

  void _loadTexture() {
    _clearTexture();
    final provider = widget.texture;
    if (provider == null) return;
    final stream = provider.resolve(createLocalImageConfiguration(context));
    _stream = stream;
    final listener = ImageStreamListener(
      (info, _) {
        final image = info.image;
        final usable =
            image.width >= 64 &&
            image.width % 64 == 0 &&
            (image.height == image.width || image.height * 2 == image.width);
        final copy = usable ? image.clone() : null;
        info.dispose();
        if (!mounted || !identical(stream, _stream)) {
          copy?.dispose();
          return;
        }
        setState(() {
          _image?.dispose();
          _image = copy;
        });
      },
      onError: (Object error, StackTrace? stackTrace) {
        if (!mounted || !identical(stream, _stream)) return;
        setState(() {
          _image?.dispose();
          _image = null;
        });
      },
    );
    _listener = listener;
    stream.addListener(listener);
  }

  @override
  void dispose() {
    _clearTexture();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    return image == null
        ? VoxelCharacter(palette: widget.palette, headOnly: true)
        : CustomPaint(painter: _SkinHeadPainter(image));
  }
}

class _SkinHeadPainter extends CustomPainter {
  const _SkinHeadPainter(this.image);

  final ui.Image image;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = image.width / 64;
    final destination = Offset.zero & size;
    final paint = Paint()
      ..isAntiAlias = false
      ..filterQuality = FilterQuality.none;
    for (final x in [8, 40]) {
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(x * scale, 8 * scale, 8 * scale, 8 * scale),
        destination,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SkinHeadPainter oldDelegate) =>
      oldDelegate.image != image;
}
