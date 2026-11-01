import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roblox/common/widgets/skin_head.dart';
import 'package:roblox/common/widgets/voxel_character.dart';

const _captureKey = ValueKey('skin-head-capture');

Future<Uint8List> _texture(int width, int height, Color face) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final scale = width / 64;
  canvas.drawRect(
    Rect.fromLTWH(0, 0, 8 * scale, 8 * scale),
    Paint()..color = Colors.green,
  );
  canvas.drawRect(
    Rect.fromLTWH(8 * scale, 8 * scale, 8 * scale, 8 * scale),
    Paint()..color = face,
  );
  canvas.drawRect(
    Rect.fromLTWH(40 * scale, 8 * scale, 4 * scale, 8 * scale),
    Paint()..color = Colors.blue,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  try {
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.png))!;
    return bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
  } finally {
    image.dispose();
    picture.dispose();
  }
}

Future<void> _mount(
  WidgetTester tester, {
  ImageProvider? texture,
  String palette = 'steve',
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Center(
        child: RepaintBoundary(
          key: _captureKey,
          child: SizedBox.square(
            dimension: 48,
            child: SkinHead(texture: texture, palette: palette),
          ),
        ),
      ),
    ),
  );
  if (texture != null) {
    await tester.runAsync(
      () => precacheImage(texture, tester.element(find.byType(SkinHead))),
    );
  }
  await tester.pump();
}

Future<List<int>> _pixel(WidgetTester tester, int x, int y) async {
  final result = await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_captureKey),
    );
    final image = await boundary.toImage();
    try {
      final bytes = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      final offset = (y * image.width + x) * 4;
      return [
        for (var channel = 0; channel < 4; channel++)
          bytes.getUint8(offset + channel),
      ];
    } finally {
      image.dispose();
    }
  });
  return result!;
}

void main() {
  testWidgets('bundled skin head follows the selected palette', (tester) async {
    await _mount(tester, palette: 'panda');
    expect(
      tester.widget<VoxelCharacter>(find.byType(VoxelCharacter)).palette,
      'panda',
    );
    await _mount(tester, palette: 'knight');
    expect(
      tester.widget<VoxelCharacter>(find.byType(VoxelCharacter)).palette,
      'knight',
    );
    expect(tester.takeException(), isNull);
  });

  for (final dimensions in [(64, 64), (64, 32), (128, 128)]) {
    testWidgets(
      'crops face and hat from ${dimensions.$1}x${dimensions.$2} skin',
      (tester) async {
        final bytes = await tester.runAsync(
          () => _texture(dimensions.$1, dimensions.$2, Colors.red),
        );
        await _mount(tester, texture: MemoryImage(bytes!));
        expect(await _pixel(tester, 12, 24), [33, 150, 243, 255]);
        expect(await _pixel(tester, 36, 24), [244, 67, 54, 255]);
        expect(find.byType(VoxelCharacter), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('replaces the previous face when selection changes', (
    tester,
  ) async {
    final red = await tester.runAsync(() => _texture(64, 64, Colors.red));
    final green = await tester.runAsync(() => _texture(64, 64, Colors.green));
    await _mount(tester, texture: MemoryImage(red!));
    expect(await _pixel(tester, 36, 24), [244, 67, 54, 255]);
    await _mount(tester, texture: MemoryImage(green!));
    expect(await _pixel(tester, 36, 24), [76, 175, 80, 255]);
    await _mount(tester, palette: 'panda');
    expect(
      tester.widget<VoxelCharacter>(find.byType(VoxelCharacter)).palette,
      'panda',
    );
    expect(tester.takeException(), isNull);
  });
}
