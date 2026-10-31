import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roblox/app/app_repositories.dart';
import 'package:roblox/features/find/data/api_find_repository.dart';
import 'package:roblox/features/maps/data/api_maps_repository.dart';
import 'package:roblox/features/skins/data/api_skins_repository.dart';
import 'package:roblox/features/servers/data/api_servers_repository.dart';
import 'package:roblox/features/history/data/history_repository.dart';
import 'support/memory_history_store.dart';

class _LocalHttp extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'localhost startup downloads and validates every catalog and media asset',
    (tester) async {
      await tester.runAsync(() async {
        SharedPreferences.setMockInitialValues({});
        await HttpOverrides.runWithHttpOverrides(() async {
          final base = Uri.parse('http://127.0.0.1:8000');
          final repositories = AppRepositories(
            find: ApiFindRepository(baseUri: base),
            maps: ApiMapsRepository(baseUri: base),
            skins: ApiSkinsRepository(baseUri: base),
            servers: ApiServersRepository(baseUri: base),
            history: JsonHistoryRepository(store: MemoryHistoryStore()),
          );
          var ready = false;
          Object? preparationError;
          final preparation = repositories.prepare().then(
            (_) {
              ready = true;
            },
            onError: (Object error) {
              preparationError = error;
              ready = true;
            },
          );
          while (!ready) {
            await Future<void>.delayed(const Duration(milliseconds: 16));
            await tester.pump(const Duration(milliseconds: 16));
          }
          await preparation;
          expect(preparationError, isNull);
          expect(repositories.initialServers!.liveStatusAvailable, isTrue);
          expect(repositories.initialServers!.servers, hasLength(20));
          expect((await repositories.skins.load()), isNotEmpty);
          expect((await repositories.maps.load()).items, isNotEmpty);
          final previous = repositories.initialServers!;
          final repeated = await repositories.servers.load();
          expect(identical(previous, repeated), isTrue);
        }, _LocalHttp());
      });
    },
    skip: Platform.environment['CHECK_LIVE_API'] != 'true',
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
