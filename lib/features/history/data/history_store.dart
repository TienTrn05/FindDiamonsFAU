import 'history_store_web.dart'
    if (dart.library.io) 'history_store_io.dart'
    as platform;

/// A JSON document; repositories do not depend on its physical storage.
abstract interface class HistoryStore {
  Future<String?> read();
  Future<void> write(String json);
}

HistoryStore createHistoryStore() => platform.createHistoryStore();
