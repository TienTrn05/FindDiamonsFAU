import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roblox/features/servers/data/servers_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the four reference servers bundle real animated GIF banners', () async {
    final catalog = await const JsonServersRepository().load();
    for (final id in ['complex', 'mystic', 'sun', 'mchub']) {
      final server = catalog.servers.singleWhere((item) => item.id == id);
      expect(server.bannerImage, endsWith('.gif'), reason: id);
      final bytes = await rootBundle.load(server.bannerImage);
      final codec = await ui.instantiateImageCodec(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
      try {
        expect(codec.frameCount, greaterThan(1), reason: id);
        final first = await codec.getNextFrame();
        expect(first.image.width, 468, reason: id);
        expect(first.image.height, 60, reason: id);
        expect(first.duration, greaterThan(Duration.zero), reason: id);
        first.image.dispose();
        final next = await codec.getNextFrame();
        expect(next.duration, greaterThan(Duration.zero), reason: id);
        next.image.dispose();
      } finally {
        codec.dispose();
      }
    }
  });
}
