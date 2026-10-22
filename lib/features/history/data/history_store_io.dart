import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'history_store.dart';

HistoryStore createHistoryStore() => HistoryFileStore();

/// Stored in the app's private support directory, outside bundled assets.
class HistoryFileStore implements HistoryStore {
  HistoryFileStore({Future<Directory> Function()? directory})
    : _directory = directory ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _directory;

  Future<File> _file() async {
    final directory = await _directory();
    await directory.create(recursive: true);
    return File('${directory.path}${Platform.pathSeparator}history.json');
  }

  @override
  Future<String?> read() async {
    final file = await _file();
    return await file.exists() ? file.readAsString() : null;
  }

  @override
  Future<void> write(String json) async {
    final file = await _file();
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(json, flush: true);
    // Replace only after the complete JSON document has reached disk.
    await temporary.rename(file.path);
  }
}
