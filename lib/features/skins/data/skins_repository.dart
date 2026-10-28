import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/json_asset_source.dart';
import '../models/skin_item.dart';

abstract interface class SkinsRepository {
  Future<List<SkinItem>> load({String query = ''});
  Set<String> get unlocked;
  Future<bool> unlock(String id);
}

class JsonSkinsRepository implements SkinsRepository {
  JsonSkinsRepository({this.source = const JsonAssetSource()});
  final JsonAssetSource source;
  static const unlockedKey = 'rewarded_unlocked_skins_v1';
  final Set<String> _unlocked = {};
  Future<void>? _restoring;

  @override
  Set<String> get unlocked => Set.unmodifiable(_unlocked);

  Future<void> _restore() => _restoring ??= () async {
    try {
      final preferences = await SharedPreferences.getInstance();
      _unlocked.addAll(preferences.getStringList(unlockedKey) ?? const []);
    } catch (error) {
      debugPrint('Skin unlock storage unavailable: $error');
    }
  }();

  @override
  Future<bool> unlock(String id) async {
    await _restore();
    _unlocked.add(id);
    try {
      final preferences = await SharedPreferences.getInstance();
      return await preferences.setStringList(unlockedKey, _unlocked.toList());
    } catch (error) {
      debugPrint('Skin unlock could not be saved: $error');
      return false;
    }
  }

  @override
  Future<List<SkinItem>> load({String query = ''}) async {
    final json = await source.read('assets/data/skins/skins.json');
    await _restore();
    final skins = (json['skins'] as List)
        .map((e) => SkinItem.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return skins;
    return skins
        .where(
          (skin) =>
              skin.name.toLowerCase().contains(normalizedQuery) ||
              skin.palette.toLowerCase().contains(normalizedQuery) ||
              (skin.category?.toLowerCase().contains(normalizedQuery) ??
                  false),
        )
        .toList(growable: false);
  }
}
