import '../../../core/data/json_asset_source.dart';
import '../models/server_catalog.dart';

abstract interface class ServersRepository {
  Future<ServerCatalog> load();
}

abstract interface class RefreshableServersRepository
    implements ServersRepository {
  Future<ServerCatalog> refresh();
}

class JsonServersRepository implements ServersRepository {
  const JsonServersRepository({this.source = const JsonAssetSource()});
  final JsonAssetSource source;

  @override
  Future<ServerCatalog> load() async => ServerCatalog.fromJson(
    await source.read('assets/data/servers/servers.json'),
  );
}
