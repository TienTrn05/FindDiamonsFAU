import '../features/find/data/find_repository.dart';
import '../features/help/data/help_repository.dart';
import '../features/history/data/history_repository.dart';
import '../features/maps/data/maps_repository.dart';
import '../features/servers/data/servers_repository.dart';
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
  }) : find = find ?? JsonFindRepository(),
       history = history ?? JsonHistoryRepository(),
       skins = skins ?? JsonSkinsRepository(),
       servers = servers ?? const JsonServersRepository(),
       maps = maps ?? JsonMapsRepository(),
       help = help ?? const JsonHelpRepository();

  final FindRepository find;
  final HistoryRepository history;
  final SkinsRepository skins;
  final ServersRepository servers;
  final MapsRepository maps;
  final HelpRepository help;
}
