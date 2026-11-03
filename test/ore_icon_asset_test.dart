import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roblox/common/widgets/ore_art.dart';

void main() {
  testWidgets('available ore block assets render in place of painted icons', (
    tester,
  ) async {
    for (final ore in [
      Ore.diamond,
      Ore.copper,
      Ore.coal,
      Ore.lapis,
      Ore.redstone,
      Ore.gold,
      Ore.emerald,
      Ore.iron,
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: OreIcon(ore: ore, size: 80)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final image = tester.widget<Image>(
        find.descendant(of: find.byType(OreIcon), matching: find.byType(Image)),
      );
      final provider = image.image as ResizeImage;
      expect(
        (provider.imageProvider as AssetImage).assetName,
        oreBlockAsset(ore),
      );
      expect(tester.takeException(), isNull, reason: ore.name);
    }

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: OreIcon(ore: Ore.stone)),
      ),
    );
    expect(
      find.descendant(of: find.byType(OreIcon), matching: find.byType(Image)),
      findsNothing,
    );
  });
}
