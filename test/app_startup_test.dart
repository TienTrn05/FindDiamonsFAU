import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roblox/app/app.dart';
import 'package:roblox/app/app_repositories.dart';
import 'package:roblox/app/navigation/app_shell.dart';
import 'package:roblox/common/widgets/app_loading_page.dart';
import 'package:roblox/core/monetization/ads_runtime.dart';
import 'package:roblox/core/monetization/app_monetization.dart';
import 'package:roblox/features/find/data/find_repository.dart';
import 'package:roblox/features/maps/data/maps_repository.dart';
import 'package:roblox/features/skins/data/skins_repository.dart';
import 'package:roblox/features/servers/data/servers_repository.dart';
import 'package:roblox/features/servers/models/server_catalog.dart';
import 'package:roblox/core/data/json_asset_source.dart';
import 'package:roblox/features/help/data/help_repository.dart';
import 'package:roblox/features/history/data/history_repository.dart';
import 'support/memory_history_store.dart';

final _json = <String, String>{};

class _Bundle extends CachingAssetBundle {
  @override
  Future<String> loadString(String key, {bool cache = true}) =>
      SynchronousFuture(_json[key]!);
  @override
  Future<ByteData> load(String key) => rootBundle.load(key);
}

class _PendingServers implements ServersRepository {
  var calls = 0;
  final pending = Completer<ServerCatalog>();
  @override
  Future<ServerCatalog> load() {
    calls++;
    return pending.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final name in [
      'find',
      'maps',
      'skins',
      'servers',
      'history',
      'help',
    ]) {
      final path = 'assets/data/$name/$name.json';
      _json[path] = await rootBundle.loadString(path);
    }
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'startup stays on loading until every catalog is ready and reuses the prepared data',
    (tester) async {
      final servers = _PendingServers();
      final access = AppMonetization(adsRuntime: AdsRuntime(enabled: false));
      addTearDown(access.dispose);
      final source = JsonAssetSource(bundle: _Bundle());
      final repositories = AppRepositories(
        find: JsonFindRepository(source: source),
        maps: JsonMapsRepository(source: source),
        skins: JsonSkinsRepository(source: source),
        servers: servers,
        help: JsonHelpRepository(source: source),
        history: JsonHistoryRepository(
          source: source,
          store: MemoryHistoryStore(),
        ),
      );
      await tester.pumpWidget(
        MyApp(
          skipOnboarding: true,
          repositories: repositories,
          monetization: access,
        ),
      );
      await tester.pump(const Duration(seconds: 5));
      expect(find.byType(AppLoadingPage), findsOneWidget);
      expect(find.byType(AppShell), findsNothing);
      final catalog = await JsonServersRepository(source: source).load();
      servers.pending.complete(catalog);
      await tester.pumpAndSettle();
      expect(find.byType(AppLoadingPage), findsNothing);
      expect(find.byType(AppShell), findsOneWidget);
      expect(servers.calls, 1);
      await tester.tap(find.byKey(const ValueKey('nav-servers')));
      await tester.pumpAndSettle();
      expect(servers.calls, 1);
      expect(find.text('Complex Gaming'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
