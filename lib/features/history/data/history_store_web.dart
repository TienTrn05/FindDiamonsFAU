import 'package:shared_preferences/shared_preferences.dart';

import 'history_store.dart';

HistoryStore createHistoryStore() => _BrowserHistoryStore();

/// Browser builds persist the same JSON document in local storage.
class _BrowserHistoryStore implements HistoryStore {
  static const _key = 'digging_history_json_v1';

  @override
  Future<String?> read() async =>
      (await SharedPreferences.getInstance()).getString(_key);

  @override
  Future<void> write(String json) async {
    final saved = await (await SharedPreferences.getInstance()).setString(
      _key,
      json,
    );
    if (!saved) throw StateError('History could not be saved');
  }
}
