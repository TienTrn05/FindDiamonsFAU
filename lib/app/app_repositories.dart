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

/// App composition only; each implementation and its data stay in its feature.
class AppRepositories {
  AppRepositories({
    FindRepository? find,
    HistoryRepository? history,
    SkinsRepository? skins,
    ServersRepository? servers,
    MapsRepository? maps,
    HelpRepository? help,
  }) : find = find ?? ApiFindRepository(),
       history = history ?? JsonHistoryRepository(),
       skins = skins ?? ApiSkinsRepository(),
       servers = servers ?? ApiServersRepository(),
       maps = maps ?? ApiMapsRepository(),
       help = help ?? const JsonHelpRepository();

  final FindRepository find;
  final HistoryRepository history;
  final SkinsRepository skins;
  final ServersRepository servers;
  final MapsRepository maps;
  final HelpRepository help;
}
