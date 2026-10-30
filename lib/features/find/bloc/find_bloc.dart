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
  String? _selectedOreId;
  String? versionId;
  bool searching = false;

  @override
  Future<FindCatalog> fetch() async {
    final catalog = await repository.load();
    if (catalog.versions.isEmpty) {
      throw const FormatException('No supported game versions found.');
    }
    return FindCatalog(
      title: catalog.title,
      help: catalog.help,
      versions: catalog.versions,
      ores: catalog.ores,
      positions: catalog.positions,
    );
  }

  List<OreOption> get availableOres {
    if (data == null) return const [];
    final selectedVersion = version.apiVersion;
    if (selectedVersion.isEmpty) return data!.ores;
    return data!.ores
        .where((ore) => _versionAtLeast(selectedVersion, ore.availableFrom))
        .toList(growable: false);
  }

  OreOption get ore {
    final ores = availableOres;
    if (ores.isEmpty) {
      throw StateError('No ores are available for this version.');
    }
    final selectedIndex = ores.indexWhere((ore) => ore.id == _selectedOreId);
    final index = selectedIndex >= 0
        ? selectedIndex
        : oreIndex.clamp(0, ores.length - 1).toInt();
    return ores[index];
  }

  GameVersion get version => data!.versions.firstWhere(
    (v) => v.id == versionId,
    orElse: () => data!.versions.first,
  );

  void changeOre(int delta) {
    final ores = availableOres;
    if (data == null || searching || ores.isEmpty) return;
    final current = ores.indexWhere((ore) => ore.id == _selectedOreId);
    final currentIndex = current >= 0 ? current : oreIndex;
    oreIndex = (currentIndex + delta) % ores.length;
    if (oreIndex < 0) oreIndex += ores.length;
    _selectedOreId = ores[oreIndex].id;
    refresh();
  }

  void selectVersion(String value) {
    versionId = value;
    final ores = availableOres;
    if (ores.isNotEmpty && !ores.any((ore) => ore.id == _selectedOreId)) {
      oreIndex = 0;
      _selectedOreId = ores.first.id;
    }
    refresh();
  }

  bool _versionAtLeast(String version, String minimum) {
    final current = version.split('.').map(int.tryParse).toList();
    final required = minimum.split('.').map(int.tryParse).toList();
    for (var index = 0; index < 2; index++) {
      final currentPart = index < current.length ? current[index] ?? 0 : 0;
      final requiredPart = index < required.length ? required[index] ?? 0 : 0;
      if (currentPart != requiredPart) return currentPart > requiredPart;
    }
    return true;
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
