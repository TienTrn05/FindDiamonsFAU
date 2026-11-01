import '../../../core/bloc/resource_controller.dart';
import '../data/servers_repository.dart';
import '../models/server_catalog.dart';

class ServersBloc extends ResourceController<ServerCatalog> {
  ServersBloc(this.repository, {ServerCatalog? initialData, this.prepare}) {
    data = initialData;
  }
  final ServersRepository repository;
  final Future<void> Function(ServerCatalog)? prepare;
  bool _forceRefresh = false;
  bool _disposed = false;
  Future<void>? _synchronizing;

  Future<void> checkForUpdates() => _synchronizing ??= _checkForUpdates()
      .whenComplete(() => _synchronizing = null);

  Future<void> _checkForUpdates() async {
    if (_disposed || loading) return;
    final source = repository;
    if (source is! RefreshableServersRepository) return;
    try {
      final next = await source.load();
      if (_disposed || identical(next, data)) return;
      final previousRevision = data?.fetchedAt;
      if (previousRevision != null &&
          (next.fetchedAt == null ||
              !next.fetchedAt!.isAfter(previousRevision))) {
        return;
      }
      await prepare?.call(next);
      if (_disposed) return;
      data = next;
      error = null;
      refresh();
    } catch (_) {
      // A failed poll/preload never clears or republishes the visible snapshot.
    }
  }

  Future<void> reload() async {
    if (loading) return load();
    _forceRefresh = true;
    try {
      await load();
    } finally {
      _forceRefresh = false;
    }
  }

  @override
  Future<ServerCatalog> fetch() async {
    final source = repository;
    final catalog =
        await (_forceRefresh && source is RefreshableServersRepository
            ? source.refresh()
            : source.load());
    await prepare?.call(catalog);
    return catalog;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
