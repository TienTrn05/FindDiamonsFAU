import 'dart:async';

import '../../../core/bloc/resource_controller.dart';
import '../../../core/models/search_record.dart';
import '../data/find_repository.dart';
import '../models/find_catalog.dart';

class FindBloc extends ResourceController<FindCatalog> {
  FindBloc(
    this.repository, {
    this.minimumSearchDuration = const Duration(milliseconds: 1100),
  });
  final FindRepository repository;
  final Duration minimumSearchDuration;
  Timer? _minimumTimer;
  Completer<void>? _minimumWait;
  int oreIndex = 0;
  String? versionId;
  bool searching = false;

  @override
  Future<FindCatalog> fetch() => repository.load();

  OreOption get ore => data!.ores[oreIndex];
  GameVersion get version => data!.versions.firstWhere(
    (v) => v.id == versionId,
    orElse: () => data!.versions.first,
  );

  void changeOre(int delta) {
    if (data == null || searching) return;
    oreIndex = (oreIndex + delta) % data!.ores.length;
    refresh();
  }

  void selectVersion(String value) {
    versionId = value;
    refresh();
  }

  Future<SearchRecord?> search({
    required int x,
    required int z,
    required String seed,
  }) async {
    if (searching || data == null) return null;
    searching = true;
    refresh();
    final minimumWait = _minimumWait = Completer<void>();
    _minimumTimer = Timer(minimumSearchDuration, minimumWait.complete);
    try {
      final result = Future<SearchRecord>.sync(
        () => repository.search(
          FindQuery(x: x, z: z, seed: seed, version: version, ore: ore),
        ),
      );
      final completed = await Future.wait<Object?>([
        result,
        minimumWait.future,
      ]);
      return completed.first as SearchRecord;
    } finally {
      searching = false;
      refresh();
    }
  }

  @override
  void dispose() {
    _minimumTimer?.cancel();
    final wait = _minimumWait;
    if (wait != null && !wait.isCompleted) wait.complete();
    super.dispose();
  }
}
