import '../../../core/models/search_record.dart';

class GameVersion {
  const GameVersion({
    required this.id,
    required this.label,
    this.edition = 'java',
    this.apiVersion = '',
  });
  factory GameVersion.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final label = json['label'] as String;
    final version = RegExp(r'\d+\.\d+').firstMatch(label)?.group(0) ?? '';
    return GameVersion(
      id: id,
      label: label,
      edition: id.startsWith('bedrock') ? 'bedrock' : 'java',
      apiVersion: version,
    );
  }
  final String id;
  final String label;
  final String edition;
  final String apiVersion;
}

class OreOption {
  const OreOption({
    required this.id,
    required this.name,
    this.availableFrom = '1.16',
  });
  factory OreOption.fromJson(Map<String, dynamic> json) => OreOption(
    id: json['id'] as String,
    name: json['name'] as String,
    availableFrom: json['availableFrom'] as String? ?? '1.16',
  );
  final String id;
  final String name;
  final String availableFrom;
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
