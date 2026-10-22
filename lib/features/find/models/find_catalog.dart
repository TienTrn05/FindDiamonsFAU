import '../../../core/models/search_record.dart';

class GameVersion {
  const GameVersion({required this.id, required this.label});
  factory GameVersion.fromJson(Map<String, dynamic> json) =>
      GameVersion(id: json['id'] as String, label: json['label'] as String);
  final String id;
  final String label;
}

class OreOption {
  const OreOption({required this.id, required this.name});
  factory OreOption.fromJson(Map<String, dynamic> json) =>
      OreOption(id: json['id'] as String, name: json['name'] as String);
  final String id;
  final String name;
}

class FindCatalog {
  const FindCatalog({
    required this.title,
    required this.help,
    required this.versions,
    required this.ores,
    required this.positions,
  });
  factory FindCatalog.fromJson(Map<String, dynamic> json) => FindCatalog(
    title: json['title'] as String,
    help: json['help'] as String,
    versions: (json['versions'] as List)
        .map((e) => GameVersion.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
    ores: (json['ores'] as List)
        .map((e) => OreOption.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
    positions: (json['positions'] as List)
        .map((e) => OrePosition.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
  );
  final String title;
  final String help;
  final List<GameVersion> versions;
  final List<OreOption> ores;
  final List<OrePosition> positions;
}

class FindQuery {
  const FindQuery({
    required this.x,
    required this.z,
    required this.seed,
    required this.version,
    required this.ore,
  });
  final int x;
  final int z;
  final String seed;
  final GameVersion version;
  final OreOption ore;
}
