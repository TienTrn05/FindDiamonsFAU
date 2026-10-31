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
  List<String> versionsFor(String edition) {
    final api = data!.seedVersions[edition];
    final versions = api != null ? api.toSet() : <String>{};
    if (api == null) {
      for (final item in data!.items.where(
        (item) => item.category == 'Seeds',
      )) {
        for (final version in item.versions) {
          final match = RegExp(
            r'^(\d+(?:\.\d+)*)(?:\s+(Java|Bedrock))?$',
            caseSensitive: false,
          ).firstMatch(version);
          if (match == null) continue;
          final itemEdition = (match.group(2) ?? item.seedEdition)
              .toLowerCase();
          if (itemEdition == edition || itemEdition == 'both') {
            versions.add(match.group(1)!);
          }
        }
      }
    }
    final sorted = versions.toList();
    sorted.sort((a, b) {
      final left = a.split('.').map(int.parse).toList();
      final right = b.split('.').map(int.parse).toList();
      for (var i = 0; i < left.length || i < right.length; i++) {
        final comparison = (i < right.length ? right[i] : 0).compareTo(
          i < left.length ? left[i] : 0,
        );
        if (comparison != 0) return comparison;
      }
      return 0;
    });
    return sorted;
  }

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
                : item.category == category ||
                      item.categories.contains(category)),
      )
      .where(
        (item) =>
            category != 'Seeds' ||
            seedVersion == null ||
            _matchesVersion(item, seedVersion!),
      )
      .toList(growable: false);

  bool _matchesVersion(MapItem item, String selection) {
    final parts = selection.split(' ');
    final edition = parts.last.toLowerCase();
    return item.versions.any((version) {
      if (version.toLowerCase() == selection.toLowerCase()) return true;
      final itemEdition = item.seedEdition.toLowerCase();
      return version == parts.first &&
          (itemEdition == edition || itemEdition == 'both');
    });
  }

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
