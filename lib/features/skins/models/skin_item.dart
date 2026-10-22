class SkinItem {
  const SkinItem({
    required this.id,
    required this.name,
    required this.palette,
    required this.locked,
  });
  factory SkinItem.fromJson(Map<String, dynamic> json) => SkinItem(
    id: json['id'] as String,
    name: json['name'] as String,
    palette: json['palette'] as String,
    locked: json['locked'] as bool,
  );
  final String id;
  final String name;
  final String palette;
  final bool locked;
}
