class SkinItem {
  const SkinItem({
    required this.id,
    required this.name,
    required this.palette,
    required this.locked,
    this.category,
    this.previewUrl,
    this.downloadUrl,
    this.sourceUrl,
  });
  factory SkinItem.fromJson(Map<String, dynamic> json) => SkinItem(
    id: json['id'] as String,
    name: json['name'] as String,
    palette: json['palette'] as String,
    locked: json['locked'] as bool,
    category: json['category'] as String?,
  );
  final String id;
  final String name;
  final String palette;
  final bool locked;
  final String? category;
  final Uri? previewUrl;
  final Uri? downloadUrl;
  final Uri? sourceUrl;
}
