import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:roblox/features/servers/data/api_servers_repository.dart';
import 'package:roblox/features/servers/bloc/servers_bloc.dart';

// Match the localhost API contract, including its cached image paths and
// boolean/null status values (the bundled demo catalog uses a different shape).
Map<String, dynamic> catalogItem(String id, String style) => {
  'id': id,
  'name': 'Server $id',
  'edition': 'java',
  'address': '$id.example.com',
  'bedrockAddress': 'bedrock.$id.example.com',
  'tags': ['SMP', 'Survival'],
  'banner': '/api/assets/server-banners/$id.gif',
  'bannerSource': 'https://external.invalid/$id.gif',
  'bannerStyle': style,
};

void main() {
  late HttpServer server;
  late ApiServersRepository repository;
  var liveRequests = 0;
  var catalogRequests = 0;
  var catalogFail = false;
  var revision = 1700000000000;
  var now = DateTime.utc(2026, 10, 31);
  var fail = false;
  var interrupt = false;
  Object? liveServers;

  setUp(() async {
    liveRequests = 0;
    catalogRequests = 0;
    catalogFail = false;
    revision = 1700000000000;
    now = DateTime.utc(2026, 10, 31);
    fail = false;
    interrupt = false;
    liveServers = [
      {'id': 'c', 'online': null, 'playersOnline': null, 'playersMax': null},
      {'id': 'b', 'online': false, 'playersOnline': 90, 'playersMax': 100},
      {
        'id': 'a',
        'online': true,
        'playersOnline': 0,
        'playersMax': 3000,
        'version': '1.21',
        'motd': 'Welcome!',
        'icon': 'data:image/png;base64,AA==',
      },
    ];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    repository = ApiServersRepository(
      baseUri: Uri.parse('http://127.0.0.1:${server.port}'),
      now: () => now,
    );
    server.listen((request) async {
      request.response.headers.contentType = ContentType.json;
      if (request.uri.path.endsWith('/catalog')) {
        catalogRequests++;
        if (catalogFail) {
          request.response.statusCode = HttpStatus.serviceUnavailable;
          await request.response.close();
          return;
        }
        request.response.write(
          jsonEncode({
            'servers': [
              catalogItem('a', 'logo'),
              catalogItem('b', 'full'),
              catalogItem('c', 'icon'),
            ],
          }),
        );
      } else {
        liveRequests++;
        if (interrupt && liveRequests == 1) {
          final socket = await request.response.detachSocket(
            writeHeaders: false,
          );
          socket.write(
            'HTTP/1.1 200 OK\r\nContent-Length: 9999\r\n\r\n{"servers":[',
          );
          await socket.flush();
          await socket.close();
          return;
        }
        if (fail) {
          request.response.statusCode = HttpStatus.serviceUnavailable;
        } else {
          request.response.write(
            jsonEncode({'fetchedAt': revision, 'servers': liveServers}),
          );
        }
      }
      await request.response.close();
    });
  });
  tearDown(() async => server.close(force: true));

  test(
    'joins live status by id and uses backend-hosted banner variants',
    () async {
      final result = await repository.load();
      expect(result.liveStatusAvailable, isTrue);
      expect(result.servers, hasLength(3));
      expect(
        result.fetchedAt,
        DateTime.fromMillisecondsSinceEpoch(1700000000000),
      );
      final a = result.servers[0];
      expect(a.currentPlayers, 0);
      expect(a.maximumPlayers, 3000);
      expect(a.availability, isTrue);
      expect(a.version, '1.21');
      expect(a.motd, 'Welcome!');
      expect(a.icon, startsWith('data:image/png'));
      expect(a.supportsJava, isTrue);
      expect(a.supportsBedrock, isTrue);
      for (final item in result.servers) {
        expect(
          item.bannerUrl.toString(),
          'http://127.0.0.1:${server.port}/api/assets/server-banners/${item.id}.gif',
        );
      }
      expect(result.servers.map((item) => item.bannerStyle), [
        'logo',
        'full',
        'icon',
      ]);
      expect(result.servers[1].availability, isFalse);
      expect(result.servers[1].currentPlayers, isNull);
      expect(result.servers[2].availability, isNull);
      expect(result.servers[2].currentPlayers, isNull);
    },
  );

  test('retries a response interrupted while receiving its body', () async {
    interrupt = true;
    final result = await repository.load();
    expect(liveRequests, 2);
    expect(result.liveStatusAvailable, isTrue);
    expect(result.servers.first.maximumPlayers, 3000);
  });

  test(
    'unavailable status remains unknown, then recovers and preserves last good values',
    () async {
      fail = true;
      final unavailable = await repository.load();
      expect(liveRequests, 2);
      expect(unavailable.liveStatusAvailable, isFalse);
      expect(unavailable.servers.first.availability, isNull);
      expect(unavailable.servers.first.currentPlayers, isNull);
      fail = false;
      final recovered = await repository.refresh();
      expect(recovered.liveStatusAvailable, isTrue);
      fail = true;
      final stale = await repository.refresh();
      expect(identical(stale, recovered), isTrue);
      expect(stale.servers.first.maximumPlayers, 3000);
      expect(stale.fetchedAt, recovered.fetchedAt);
    },
  );

  test(
    'invalid status response is unavailable rather than a fake online count',
    () async {
      liveServers = 'invalid';
      final result = await repository.load();
      expect(result.liveStatusAvailable, isFalse);
      expect(result.servers.first.currentPlayers, isNull);
    },
  );

  test('online with missing counts does not invent zero players', () async {
    liveServers = [
      {'id': 'a', 'online': true},
    ];
    final result = await repository.load();
    expect(result.servers.first.availability, isTrue);
    expect(result.servers.first.currentPlayers, isNull);
    expect(result.servers.first.maximumPlayers, isNull);
  });

  test(
    'coalesces concurrent loads and caches the same snapshot for one minute',
    () async {
      final results = await Future.wait([repository.load(), repository.load()]);
      expect(identical(results[0], results[1]), isTrue);
      expect(catalogRequests, 1);
      expect(liveRequests, 1);
      now = now.add(const Duration(seconds: 59));
      expect(identical(await repository.load(), results[0]), isTrue);
      expect(liveRequests, 1);
      now = now.add(const Duration(seconds: 1));
      expect(identical(await repository.load(), results[0]), isTrue);
      expect(liveRequests, 2);
    },
  );

  test(
    'explicit refresh bypasses a fresh cache and coalesces duplicate refreshes',
    () async {
      await repository.load();
      revision++;
      liveServers = [
        {'id': 'a', 'online': true, 'playersOnline': 42, 'playersMax': 100},
      ];
      final results = await Future.wait([
        repository.refresh(),
        repository.refresh(),
      ]);
      expect(liveRequests, 2);
      expect(results.first.servers.first.currentPlayers, 42);
      expect(identical(results.first, results.last), isTrue);
    },
  );

  test(
    'cached catalog and last status survive a complete network failure',
    () async {
      final original = await repository.load();
      catalogFail = true;
      fail = true;
      final offline = await repository.refresh();
      expect(offline.servers.length, original.servers.length);
      expect(offline.servers.first.bannerUrl, original.servers.first.bannerUrl);
      expect(offline.servers.first.maximumPlayers, 3000);
      expect(identical(offline, original), isTrue);
      expect(identical(await repository.load(), offline), isTrue);
      now = now.add(const Duration(seconds: 60));
      catalogFail = false;
      fail = false;
      expect((await repository.load()).liveStatusAvailable, isTrue);
    },
  );

  test(
    'page reload bypasses the repository cache while normal loads reuse it',
    () async {
      final bloc = ServersBloc(repository);
      addTearDown(bloc.dispose);
      await bloc.load();
      await bloc.load();
      expect(liveRequests, 1);
      revision++;
      liveServers = [
        {'id': 'a', 'online': true, 'playersOnline': 123, 'playersMax': 3000},
      ];
      await bloc.reload();
      expect(liveRequests, 2);
      expect(bloc.data!.servers.first.currentPlayers, 123);
    },
  );

  test(
    'a new batch with failed individual lookups keeps each last known status',
    () async {
      final original = await repository.load();
      revision++;
      liveServers = [
        {'id': 'a', 'online': null, 'playersOnline': null},
        {'id': 'b', 'online': null, 'playersOnline': null},
        {'id': 'c', 'online': null, 'playersOnline': null},
      ];
      final updated = await repository.refresh();
      expect(updated.fetchedAt, isNot(original.fetchedAt));
      expect(updated.servers.first.availability, isTrue);
      expect(updated.servers.first.currentPlayers, 0);
      expect(updated.servers.first.maximumPlayers, 3000);
      expect(updated.servers[1].availability, isFalse);
    },
  );
}
