import '../core/models/search_record.dart';
import '../features/find/data/find_repository.dart';
import '../features/find/models/find_catalog.dart';
import '../features/help/data/help_repository.dart';
import '../features/help/models/help_content.dart';
import '../features/maps/data/maps_repository.dart';
import '../features/maps/models/map_catalog.dart';
import '../features/skins/data/skins_repository.dart';
import '../features/skins/models/skin_item.dart';

class _CatalogCache<T> {
  Future<T>? _pending;
  Future<T> load(Future<T> Function() fetch) =>
      _pending ??= fetch().catchError((Object error, StackTrace stack) {
        _pending = null;
        Error.throwWithStackTrace(error, stack);
      });
}

class CachedFindRepository implements FindRepository {
  CachedFindRepository(this.source);
  final FindRepository source;
  final _cache = _CatalogCache<FindCatalog>();
  @override
  Future<FindCatalog> load() => _cache.load(source.load);
  @override
  Future<SearchRecord> search(FindQuery query) => source.search(query);
}

class CachedMapsRepository implements MapsRepository {
  CachedMapsRepository(this.source);
  final MapsRepository source;
  final _cache = _CatalogCache<MapCatalog>();
  @override
  Future<MapCatalog> load() => _cache.load(source.load);
  @override
  Set<String> get favourites => source.favourites;
  @override
  Set<String> get unlocked => source.unlocked;
  @override
  void toggleFavourite(String id) => source.toggleFavourite(id);
  @override
  Future<bool> unlock(String id) => source.unlock(id);
}

class CachedSkinsRepository implements SkinsRepository {
  CachedSkinsRepository(this.source);
  final SkinsRepository source;
  final _cache = _CatalogCache<List<SkinItem>>();
  @override
  Future<List<SkinItem>> load({String query = ''}) => query.trim().isEmpty
      ? _cache.load(() => source.load())
      : source.load(query: query);
  @override
  Set<String> get unlocked => source.unlocked;
  @override
  Future<bool> unlock(String id) => source.unlock(id);
}

class CachedHelpRepository implements HelpRepository {
  CachedHelpRepository(this.source);
  final HelpRepository source;
  final _cache = _CatalogCache<HelpContent>();
  @override
  Future<HelpContent> load() => _cache.load(source.load);
}
