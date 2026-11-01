import '../features/find/data/find_repository.dart';
import '../features/find/data/api_find_repository.dart';
import '../features/help/data/help_repository.dart';
import '../features/history/data/history_repository.dart';
import '../features/maps/data/maps_repository.dart';
import '../features/maps/data/api_maps_repository.dart';
import '../features/servers/data/servers_repository.dart';
import '../features/servers/data/api_servers_repository.dart';
import '../features/skins/data/api_skins_repository.dart';
import '../features/skins/data/skins_repository.dart';
import '../core/network/app_image_cache.dart';
import '../features/servers/models/server_catalog.dart';
import '../features/servers/data/server_media_cache.dart';
import 'cached_repositories.dart';

/// App composition only; each implementation and its data stay in its feature.
class AppRepositories {
  AppRepositories({
    FindRepository? find,
    HistoryRepository? history,
    SkinsRepository? skins,
    ServersRepository? servers,
    MapsRepository? maps,
    HelpRepository? help,
  }) : find = CachedFindRepository(find ?? ApiFindRepository()),
       history = history ?? JsonHistoryRepository(),
       skins = CachedSkinsRepository(skins ?? ApiSkinsRepository()),
       servers = servers ?? ApiServersRepository(),
       maps = CachedMapsRepository(maps ?? ApiMapsRepository()),
       help = CachedHelpRepository(help ?? const JsonHelpRepository());

  final FindRepository find;
  final HistoryRepository history;
  final SkinsRepository skins;
  final ServersRepository servers;
  final MapsRepository maps;
  final HelpRepository help;
  ServerCatalog? _initialServers;
  ServerCatalog? get initialServers => _initialServers;
  Future<void> prepareServers(ServerCatalog catalog) async {
    await prepareServerImages(catalog);
    _initialServers = catalog;
  }

  Future<void>? _preparing;

  Future<void> prepare() =>
      _preparing ??= _prepare().catchError((Object error, StackTrace stack) {
        _preparing = null;
        Error.throwWithStackTrace(error, stack);
      });

  Future<void> _prepare() async {
    // Start every catalog concurrently and reuse these same repositories in UI.
    await Future.wait<void>([
      find.load().then((_) {}),
      history.load().then((_) {}),
      help.load().then((_) {}),
      skins.load().then(
        (items) => AppImageCache.shared.preload([
          for (final item in items) ...[
            if (item.previewUrl != null) item.previewUrl.toString(),
            if (item.downloadUrl != null) item.downloadUrl.toString(),
          ],
        ]),
      ),
      maps.load().then(
        (catalog) => AppImageCache.shared.preload([
          for (final item in catalog.items)
            if (item.coverUrl != null) item.coverUrl!,
        ]),
      ),
      servers.load().then((catalog) async {
        if (!catalog.liveStatusAvailable ||
            catalog.servers.isEmpty ||
            !catalog.servers.any((server) => server.availability != null)) {
          throw StateError('Initial server status has not finished loading');
        }
        await prepareServers(catalog);
      }),
    ]);
  }
}
