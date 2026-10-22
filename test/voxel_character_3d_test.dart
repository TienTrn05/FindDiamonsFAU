import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roblox/common/widgets/voxel_character_3d.dart';

void main() {
  testWidgets('vertical drag rotates past the poles through a full turn', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(width: 260, height: 390, child: VoxelCharacter3D()),
        ),
      ),
    );
    String orientation() => tester
        .getSemantics(find.bySemanticsLabel('3D skin preview'))
        .getSemanticsData()
        .value;
    int verticalAngle() => int.parse(
      RegExp(r'(\d+) degrees vertical').firstMatch(orientation())!.group(1)!,
    );
    final horizontal = orientation().split(',').first;
    await tester.drag(find.byType(VoxelCharacter3D), const Offset(0, 210));
    await tester.pumpAndSettle();
    expect(verticalAngle(), inInclusiveRange(140, 200));
    expect(orientation().split(',').first, horizontal);
    await tester.drag(find.byType(VoxelCharacter3D), const Offset(0, 210));
    await tester.pumpAndSettle();
    expect(verticalAngle(), greaterThan(280));
    expect(tester.takeException(), isNull);
  });

  testWidgets('front has eyes and back has hair with no face showing through', (
    tester,
  ) async {
    const capture = ValueKey('model-capture');
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: RepaintBoundary(
            key: capture,
            child: SizedBox(width: 260, height: 390, child: VoxelCharacter3D()),
          ),
        ),
      ),
    );

    Future<(int, int)> headPixels() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(capture),
      );
      final image = await boundary.toImage();
      final data = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      var eyes = 0;
      var hair = 0;
      // Only inspect the head region; trousers use a similar blue to the eyes.
      for (var y = 0; y < image.height ~/ 3; y++) {
        for (var x = 0; x < image.width; x++) {
          final offset = (y * image.width + x) * 4;
          final r = data.getUint8(offset);
          final g = data.getUint8(offset + 1);
          final b = data.getUint8(offset + 2);
          if (b > r * 1.5 && b > g * 1.5 && b > 90) eyes++;
          if (r > 30 && r < 90 && g < 55 && b < 30) hair++;
        }
      }
      image.dispose();
      return (eyes, hair);
    }

    final front = await tester.runAsync(headPixels);
    expect(front!.$1, greaterThan(0));
    await tester.drag(find.byType(VoxelCharacter3D), const Offset(210, 0));
    await tester.pumpAndSettle();
    final back = await tester.runAsync(headPixels);
    expect(back!.$1, 0);
    expect(back.$2, greaterThan(front.$2));
  });
}
