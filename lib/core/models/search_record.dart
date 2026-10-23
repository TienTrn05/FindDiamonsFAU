import 'dart:math' as math;

class OrePosition {
  const OrePosition({
    required this.x,
    required this.y,
    required this.z,
    required this.count,
    this.found = false,
  });

  factory OrePosition.fromJson(Map<String, dynamic> json) => OrePosition(
    x: json['x'] as int,
    y: json['y'] as int,
    z: json['z'] as int,
    count: json['count'] as int,
    found: json['found'] as bool? ?? false,
  );

  final int x;
  final int y;
  final int z;
  final int count;
  final bool found;

  OrePosition withFound(bool value) =>
      OrePosition(x: x, y: y, z: z, count: count, found: value);

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'z': z,
    'count': count,
    'found': found,
  };
}

/// Shared between Find and History so neither feature depends on the other.
class SearchRecord {
  const SearchRecord({
    required this.id,
    required this.seed,
    required this.playerX,
    required this.playerZ,
    required this.version,
    required this.oreId,
    required this.oreName,
    required this.positions,
    required this.createdAt,
    this.revealedCount = 1,
  });

  factory SearchRecord.fromJson(Map<String, dynamic> json) => SearchRecord(
    id: json['id'] as String,
    seed: json['seed'] as String,
    playerX: json['playerX'] as int,
    playerZ: json['playerZ'] as int,
    version: json['version'] as String,
    oreId: json['oreId'] as String,
    oreName: json['oreName'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    revealedCount: json['revealedCount'] as int? ?? 1,
    positions: (json['positions'] as List)
        .map((item) => OrePosition.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
  );

  final String id;
  final String seed;
  final int playerX;
  final int playerZ;
  final String version;
  final String oreId;
  final String oreName;
  final List<OrePosition> positions;
  final DateTime createdAt;
  final int revealedCount;

  SearchRecord withRevealedCount(int count) => SearchRecord(
    id: id,
    seed: seed,
    playerX: playerX,
    playerZ: playerZ,
    version: version,
    oreId: oreId,
    oreName: oreName,
    positions: positions,
    createdAt: createdAt,
    revealedCount: count.clamp(math.min(1, positions.length), positions.length),
  );

  SearchRecord withFound(int index, bool found) {
    if (index < 0 || index >= positions.length) return this;
    return SearchRecord(
      id: id,
      seed: seed,
      playerX: playerX,
      playerZ: playerZ,
      version: version,
      oreId: oreId,
      oreName: oreName,
      positions: List.unmodifiable([
        for (var i = 0; i < positions.length; i++)
          i == index ? positions[i].withFound(found) : positions[i],
      ]),
      createdAt: createdAt,
      revealedCount: revealedCount,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'seed': seed,
    'playerX': playerX,
    'playerZ': playerZ,
    'version': version,
    'oreId': oreId,
    'oreName': oreName,
    'positions': positions.map((position) => position.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'revealedCount': revealedCount,
  };
}
