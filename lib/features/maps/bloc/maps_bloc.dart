import '../../../core/bloc/resource_controller.dart';
import '../data/maps_repository.dart';
import '../data/map_download_repository.dart';
import '../models/map_catalog.dart';
import 'map_download_controller.dart';

class MapsBloc extends ResourceController<MapCatalog> {
  MapsBloc(this.repository, {MapDownloadRepository? downloads})
    : _downloadRepository = downloads ?? LocalMapDownloadRepository();
  final MapsRepository repository;
  final MapDownloadRepository _downloadRepository;
  final _downloads = <String, MapDownloadController>{};

  MapDownloadController downloadFor(MapItem item) => _downloads.putIfAbsent(
    item.id,
    () => MapDownloadController(item, _downloadRepository)..restore(),
  );
  String? _category;
  String? seedVersion;
  List<String> get seedVersions => {
    for (final item in data!.items)
      if (item.category == 'Seeds') ...item.versions,
  }.toList(growable: false);
  String get category {
    final catalog = data;
    if (catalog == null) return '';
    final selected = _category ?? catalog.initialCategory;
    return catalog.categories.contains(selected)
        ? selected
        : catalog.categories.firstOrNull ?? '';
  }

  Set<String> get favourites => repository.favourites;
  bool isLocked(MapItem item, {required bool isPro}) =>
      item.locked && !isPro && !repository.unlocked.contains(item.id);

  Future<bool> unlock(String id) async {
    final saved = await repository.unlock(id);
    refresh();
    return saved;
  }

  List<MapItem> get visible => data!.items
      .where(
        (item) =>
            category == 'All' ||
            (category == 'Favourite'
                ? favourites.contains(item.id)
                : item.category == category),
      )
      .where(
        (item) =>
            category != 'Seeds' ||
            seedVersion == null ||
            item.versions.contains(seedVersion),
      )
      .toList(growable: false);

  @override
  Future<MapCatalog> fetch() => repository.load();

  void selectCategory(String value) {
    if (data?.categories.contains(value) != true) return;
    _category = value;
    refresh();
  }

  void selectSeedVersion(String? value) {
    seedVersion = value;
    refresh();
  }

  void toggleFavourite(String id) {
    repository.toggleFavourite(id);
    refresh();
  }

  @override
  void dispose() {
    for (final controller in _downloads.values) {
      controller.dispose();
    }
    super.dispose();
  }
}
