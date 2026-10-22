import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/json_asset_source.dart';
import '../models/map_catalog.dart';

abstract interface class MapsRepository {
  Future<MapCatalog> load();
  Set<String> get favourites;
  void toggleFavourite(String id);
  Set<String> get unlocked;

  /// Grants access for this device. Returns whether the grant was saved to disk.
  Future<bool> unlock(String id);
}

class JsonMapsRepository implements MapsRepository {
  JsonMapsRepository({this.source = const JsonAssetSource()});
  final JsonAssetSource source;
  final Set<String> _favourites = {};
  static const unlockedKey = 'rewarded_unlocked_maps_v1';
  final Set<String> _unlocked = {};
  Future<void>? _restoring;

  @override
  Set<String> get unlocked => Set.unmodifiable(_unlocked);

  Future<void> _restoreUnlocks() => _restoring ??= () async {
    try {
      final preferences = await SharedPreferences.getInstance();
      _unlocked.addAll(preferences.getStringList(unlockedKey) ?? const []);
    } catch (error) {
      debugPrint('Map unlock storage unavailable: $error');
    }
  }();

  @override
  Set<String> get favourites => Set.unmodifiable(_favourites);

  @override
  Future<MapCatalog> load() async {
    final json = await source.read('assets/data/maps/maps.json');
    await _restoreUnlocks();
    return MapCatalog.fromJson(json);
  }

  @override
  Future<bool> unlock(String id) async {
    await _restoreUnlocks();
    _unlocked.add(id);
    try {
      final preferences = await SharedPreferences.getInstance();
      return await preferences.setStringList(unlockedKey, _unlocked.toList());
    } catch (error) {
      debugPrint('Map unlock could not be saved: $error');
      return false;
    }
  }

  @override
  void toggleFavourite(String id) {
    if (!_favourites.add(id)) _favourites.remove(id);
  }
}
