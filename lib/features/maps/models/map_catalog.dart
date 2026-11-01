class MapItem {
  const MapItem({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.description,
    required this.category,
    required this.cover,
    required this.locked,
    this.seed,
    this.seedEdition = '',
    this.seedCategory = '',
    this.coverUrl,
    this.sourceUrl,
    this.downloadPageUrl,
    this.downloadUrl,
    this.edition = '',
    this.creator = '',
    this.categories = const [],
    this.gallery = const [],
    this.features = const [],
    this.versions = const [],
  });
  factory MapItem.fromJson(Map<String, dynamic> json) => MapItem(
    id: json['id'] as String,
    name: json['name'] as String,
    subtitle: json['subtitle'] as String,
    description: json['description'] as String,
    category: json['category'] as String,
    cover: json['cover'] as String,
    locked: json['locked'] as bool,
    seed: json['seed'] as String?,
    seedEdition: json['seedEdition'] as String? ?? '',
    seedCategory: json['seedCategory'] as String? ?? '',
    coverUrl: json['coverUrl'] as String?,
    sourceUrl: json['sourceUrl'] as String?,
    downloadPageUrl: json['downloadPageUrl'] as String?,
    downloadUrl: json['downloadUrl'] as String?,
    edition: json['edition'] as String? ?? '',
    creator: json['creator'] as String? ?? '',
    categories: List<String>.from(json['categories'] as List? ?? const []),
    gallery: List<String>.from(json['gallery'] as List? ?? const []),
    features: List<String>.from(json['features'] as List? ?? const []),
    versions: List<String>.from(json['versions'] as List? ?? const []),
  );
  final String id;
  final String name;
  final String subtitle;
  final String description;
  final String category;
  final String cover;
  final bool locked;
  final String? seed;
  final String seedEdition;
  final String seedCategory;
  final String? coverUrl;
  final String? sourceUrl;
  final String? downloadPageUrl;
  final String? downloadUrl;
  final String edition;
  final String creator;
  final List<String> categories;
  final List<String> gallery;
  final List<String> features;
  final List<String> versions;
  List<String> get images => gallery.isEmpty ? [cover] : gallery;
  List<String> get details => features.isEmpty ? [description] : features;
}

class MapCatalog {
  const MapCatalog({
    required this.title,
    required this.categories,
    required this.initialCategory,
    required this.items,
    this.seedVersions = const {},
  });
  factory MapCatalog.fromJson(Map<String, dynamic> json) => MapCatalog(
    title: json['title'] as String,
    categories: List<String>.from(json['categories'] as List),
    initialCategory: json['initialCategory'] as String,
    items: (json['items'] as List)
        .map((e) => MapItem.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
  );
  final String title;
  final List<String> categories;
  final String initialCategory;
  final List<MapItem> items;
  final Map<String, List<String>> seedVersions;
}
