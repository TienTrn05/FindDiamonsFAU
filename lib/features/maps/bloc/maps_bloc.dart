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
  String? seedEdition;
  List<String> get javaSeedVersions => _seedVersionsFor('java');
  List<String> get bedrockSeedVersions => _seedVersionsFor('bedrock');
  List<String> get seedVersions => {
    ...javaSeedVersions,
    ...bedrockSeedVersions,
  }.toList(growable: false);

  List<String> _seedVersionsFor(String edition) {
    final catalog = data;
    if (catalog == null) return const [];
    final apiVersions = edition == 'java'
        ? catalog.javaVersions
        : catalog.bedrockVersions;
    final versions = {
      ...apiVersions,
      for (final item in catalog.items)
        if (item.category == 'Seeds' &&
            item.versions.any(
              (version) => _itemVersionEdition(item, version) == edition,
            ))
          for (final version in item.versions)
            if (_itemVersionEdition(item, version) == edition)
              _bareVersion(version),
    }.toList(growable: false);
    versions.sort(_compareVersionsDescending);
    return versions;
  }

  int _compareVersionsDescending(String a, String b) {
    final numericVersion = RegExp(r'^\d+(?:\.\d+)*$');
    final aIsNumeric = numericVersion.hasMatch(a);
    final bIsNumeric = numericVersion.hasMatch(b);
    if (aIsNumeric != bIsNumeric) return aIsNumeric ? -1 : 1;
    if (!aIsNumeric) return a.compareTo(b);

    final aParts = a.split('.').map(int.parse).toList();
    final bParts = b.split('.').map(int.parse).toList();
    final count = aParts.length > bParts.length ? aParts.length : bParts.length;
    for (var index = 0; index < count; index++) {
      final aPart = index < aParts.length ? aParts[index] : 0;
      final bPart = index < bParts.length ? bParts[index] : 0;
      final comparison = bPart.compareTo(aPart);
      if (comparison != 0) return comparison;
    }
    return a.compareTo(b);
  }

  String _bareVersion(String version) => version
      .replaceFirst(RegExp(r'\s+(java|bedrock)$', caseSensitive: false), '')
      .trim();

  String _itemVersionEdition(MapItem item, String version) {
    if (item.seedEdition.isNotEmpty) return item.seedEdition.toLowerCase();
    final match = RegExp(r'\b(java|bedrock)$', caseSensitive: false)
        .firstMatch(version.trim());
    return match?.group(1)?.toLowerCase() ?? '';
  }

  bool _matchesSeedVersion(MapItem item) {
    if (seedVersion == null) return true;
    if (seedEdition != null && item.seedEdition.isNotEmpty &&
        item.seedEdition.toLowerCase() != seedEdition) {
      return false;
    }
    return item.versions.any((version) {
      final edition = _itemVersionEdition(item, version);
      return _bareVersion(version) == seedVersion &&
          (seedEdition == null || edition == seedEdition);
    });
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
            _matchesSeedVersion(item),
      )
      .toList(growable: false);

  @override
  Future<MapCatalog> fetch() => repository.load();

  void selectCategory(String value) {
    if (data?.categories.contains(value) != true) return;
    _category = value;
    refresh();
  }

  void selectSeedVersion(String? value, {String? edition}) {
    seedVersion = value;
    seedEdition = value == null ? null : edition;
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
