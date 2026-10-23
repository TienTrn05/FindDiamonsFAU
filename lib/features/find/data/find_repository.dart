import 'dart:math' as math;

import '../../../core/data/json_asset_source.dart';
import '../../../core/models/search_record.dart';
import '../models/find_catalog.dart';

abstract interface class FindRepository {
  Future<FindCatalog> load();
  Future<SearchRecord> search(FindQuery query);
}

class JsonFindRepository implements FindRepository {
  JsonFindRepository({
    this.source = const JsonAssetSource(),
    math.Random? random,
  }) : _random = random ?? math.Random();
  final JsonAssetSource source;
  final math.Random _random;
  Future<FindCatalog>? _catalog;

  @override
  Future<FindCatalog> load() => _catalog ??= _read();

  Future<FindCatalog> _read() async {
    try {
      return FindCatalog.fromJson(
        await source.read('assets/data/find/find.json'),
      );
    } catch (_) {
      _catalog = null;
      rethrow;
    }
  }

  @override
  Future<SearchRecord> search(FindQuery query) async {
    final catalog = await load();
    final now = DateTime.now();
    return SearchRecord(
      id: now.microsecondsSinceEpoch.toString(),
      seed: query.seed,
      playerX: query.x,
      playerZ: query.z,
      version: query.version.label,
      oreId: query.ore.id,
      oreName: query.ore.name,
      createdAt: now,
      revealedCount: math.min(catalog.positions.length, 1 + _random.nextInt(2)),
      positions: catalog.positions
          .map(
            (position) => OrePosition(
              x: query.x + position.x,
              y: position.y,
              z: query.z + position.z,
              count: position.count,
            ),
          )
          .toList(growable: false),
    );
  }
}
