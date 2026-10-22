import '../../../core/bloc/resource_controller.dart';
import '../data/servers_repository.dart';
import '../models/server_catalog.dart';

class ServersBloc extends ResourceController<ServerCatalog> {
  ServersBloc(this.repository);
  final ServersRepository repository;

  @override
  Future<ServerCatalog> fetch() => repository.load();
}
