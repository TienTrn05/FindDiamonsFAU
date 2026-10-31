import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roblox/features/servers/data/servers_repository.dart';
import 'package:roblox/features/servers/models/server_catalog.dart';
import 'package:roblox/features/servers/presentation/server_banner.dart';
import 'package:roblox/features/servers/presentation/servers_page.dart';
import 'package:roblox/core/network/app_image_cache.dart';

class _LocalHttp extends HttpOverrides {}

class _BannerServers implements ServersRepository {
  _BannerServers(this.first);
  final ServerItem first;
  int loads = 0;
  @override
  Future<ServerCatalog> load() async {
    loads++;
    return ServerCatalog(
      banner: '',
      servers: [
        first,
        for (var i = 0; i < 20; i++)
          ServerItem.fromApiJson({
            'id': '$i',
            'name': 'Server $i',
          }, rank: i + 2),
      ],
    );
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('an interrupted banner retries and displays the actual GIF', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final bytes = await rootBundle.load('assets/images/servers/mystic.gif');
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      var requests = 0;
      server.listen((request) async {
        requests++;
        if (requests == 1) {
          final socket = await request.response.detachSocket(
            writeHeaders: false,
          );
          socket.write(
            'HTTP/1.1 200 OK\r\nContent-Type: image/gif\r\nContent-Length: ${bytes.lengthInBytes}\r\n\r\n',
          );
          socket.add(bytes.buffer.asUint8List(bytes.offsetInBytes, 128));
          await socket.flush();
          await socket.close();
          return;
        } else {
          request.response.headers.contentType = ContentType('image', 'gif');
          request.response.add(
            bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          );
        }
        await request.response.close();
      });
      try {
        await HttpOverrides.runWithHttpOverrides(() async {
          final item = ServerItem.fromApiJson(
            {'id': 'mystic', 'name': 'MysticMC', 'bannerStyle': 'full'},
            rank: 1,
            bannerUrl: Uri.parse('http://127.0.0.1:${server.port}/banner.gif'),
          );
          // Startup resolves and validates the compressed media before showing UI.
          await AppImageCache.shared.load(item.bannerUrl.toString());
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 350,
                    child: ServerBanner(server: item),
                  ),
                ),
              ),
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 100));
          await tester.pump(); // Render the error and schedule the retry.
          await Future<void>.delayed(const Duration(milliseconds: 650));
          await tester.pump(); // Resolve the new Image instance.
          await Future<void>.delayed(const Duration(milliseconds: 250));
          await tester.pump();
          expect(requests, 2);
          for (
            var i = 0;
            i < 20 &&
                tester.widget<RawImage>(find.byType(RawImage)).image == null;
            i++
          ) {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            await tester.pump();
          }
          final image = tester.widget<RawImage>(find.byType(RawImage));
          expect(image.image, isNotNull);
          expect(image.image!.width, 468);
          expect(image.image!.height, 60);
          expect(find.text('MysticMC'), findsNothing);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());

          final repository = _BannerServers(item);
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(body: ServersPage(repository: repository)),
            ),
          );
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump();
          await Future<void>.delayed(const Duration(milliseconds: 50));
          await tester.pump();
          final banner = find.descendant(
            of: find.byKey(const ValueKey('server-mystic')),
            matching: find.byType(RawImage),
          );
          final element = tester.element(banner);
          expect(tester.widget<RawImage>(banner).image, isNotNull);
          final list = find.byKey(const PageStorageKey('server-list'));
          await tester.drag(list, const Offset(0, -2000));
          await tester.pump();
          expect(element.mounted, isTrue);
          await tester.drag(list, const Offset(0, 2000));
          await tester.pump();
          expect(identical(tester.element(banner), element), isTrue);
          expect(
            requests,
            2,
            reason: 'Scrolling and reopening use the cached GIF',
          );
          expect(repository.loads, 1);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
        }, _LocalHttp());
      } finally {
        await server.close(force: true);
      }
    });
  });
}
