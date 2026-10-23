import 'dart:convert';
import 'dart:math' as math;

import '../../../core/data/json_asset_source.dart';
import '../../../core/models/search_record.dart';
import '../models/history_data.dart';
import 'history_store.dart';

abstract interface class HistoryRepository {
  Future<HistoryData> load();
  Future<void> add(SearchRecord record);
  Future<void> reveal(String id, int count);
  Future<void> setFound(String id, int index, bool found);
  Future<void> remove(String id);
}

class JsonHistoryRepository implements HistoryRepository {
  JsonHistoryRepository({
    this.source = const JsonAssetSource(),
    HistoryStore? store,
  }) : store = store ?? createHistoryStore();
  final JsonAssetSource source;
  final HistoryStore store;
  HistoryData? _data;
  Future<void>? _restoring;
  Future<void> _pending = Future.value();

  Future<void> _restore() => _restoring ??= () async {
    try {
      final initial = await source.read('assets/data/history/history.json');
      final saved = await store.read();
      _data = HistoryData.fromJson(
        saved == null ? initial : jsonDecode(saved) as Map<String, dynamic>,
      );
    } catch (_) {
      _restoring = null;
      rethrow;
    }
  }();

  Future<void> _mutate(void Function(List<SearchRecord>) change) {
    final operation = _pending.then((_) async {
      await _restore();
      final records = [..._data!.searches];
      change(records);
      records.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _data = HistoryData(
        emptyMessage: _data!.emptyMessage,
        searches: List.unmodifiable(records),
      );
      await store.write(
        const JsonEncoder.withIndent('  ').convert({
          'schemaVersion': 1,
          'emptyMessage': _data!.emptyMessage,
          'searches': records.map((record) => record.toJson()).toList(),
        }),
      );
    });
    // A failed write is reported to its caller; subsequent actions can retry.
    _pending = operation.then<void>((_) {}, onError: (Object error) {});
    return operation;
  }

  @override
  Future<HistoryData> load() async {
    await _pending;
    await _restore();
    return _data!;
  }

  @override
  Future<void> add(SearchRecord record) => _mutate((records) {
    records.removeWhere((item) => item.id == record.id);
    records.insert(0, record);
  });

  @override
  Future<void> reveal(String id, int count) => _mutate((records) {
    final index = records.indexWhere((record) => record.id == id);
    if (index < 0) return;
    final record = records[index];
    records[index] = record.withRevealedCount(
      math.max(record.revealedCount, count),
    );
  });

  @override
  Future<void> setFound(String id, int index, bool found) => _mutate((records) {
    final recordIndex = records.indexWhere((record) => record.id == id);
    if (recordIndex < 0) return;
    records[recordIndex] = records[recordIndex].withFound(index, found);
  });

  @override
  Future<void> remove(String id) =>
      _mutate((records) => records.removeWhere((record) => record.id == id));
}
