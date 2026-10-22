import 'package:roblox/features/history/data/history_store.dart';

class MemoryHistoryStore implements HistoryStore {
  String? json;
  bool failWrite = false;

  @override
  Future<String?> read() async => json;

  @override
  Future<void> write(String value) async {
    if (failWrite) throw StateError('Disk full');
    json = value;
  }
}
