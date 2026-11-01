import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:roblox/core/network/app_image_cache.dart';

class _LocalHttp extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'compressed GIF cache retries, coalesces and survives decoded image eviction',
    () async {
      final bytes = await rootBundle.load('assets/images/servers/mystic.gif');
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      var requests = 0;
      server.listen((request) async {
        requests++;
        if (requests == 1) {
          request.response.statusCode = 503;
        } else {
          request.response.add(
            bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          );
        }
        await request.response.close();
      });
      try {
        await HttpOverrides.runWithHttpOverrides(() async {
          final cache = AppImageCache();
          final url = 'http://127.0.0.1:${server.port}/mystic.gif';
          final results = await Future.wait([cache.load(url), cache.load(url)]);
          expect(requests, 2);
          expect(identical(results.first, results.last), isTrue);
          expect(identical(await cache.load(url), results.first), isTrue);
          expect(requests, 2);
        }, _LocalHttp());
      } finally {
        await server.close(force: true);
      }
    },
    timeout: const Timeout(Duration(seconds: 15)),
  );
}
