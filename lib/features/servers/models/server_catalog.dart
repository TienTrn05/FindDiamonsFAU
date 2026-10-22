class ServerItem {
  const ServerItem({
    required this.id,
    required this.rank,
    required this.name,
    required this.tags,
    required this.online,
    required this.capacity,
    required this.address,
    required this.status,
    this.website = 'https://example.com',
    this.description =
        'Welcome to our community! Explore new worlds, build '
        'with friends and discover your next adventure. Enjoy a choice of '
        'game modes, community events and a friendly place to play. '
        'More server information will be available here soon.',
    this.bannerLabel = 'SKYBLOCK',
    this.bannerImage = 'assets/images/block_landscape.png',
    this.port = 19132,
  });
  factory ServerItem.fromJson(Map<String, dynamic> json) => ServerItem(
    id: json['id'] as String,
    rank: json['rank'] as int,
    name: json['name'] as String,
    tags: List<String>.from(json['tags'] as List),
    online: json['online'] as int,
    capacity: json['capacity'] as int,
    address: json['address'] as String,
    status: json['status'] as String,
    website: json['website'] as String? ?? 'https://example.com',
    description:
        json['description'] as String? ??
        'Welcome to our community! Explore new worlds, build with friends '
            'and discover your next adventure. Enjoy a choice of game modes, '
            'community events and a friendly place to play. '
            'More server information will be available here soon.',
    bannerLabel: json['bannerLabel'] as String? ?? 'SKYBLOCK',
    bannerImage:
        json['bannerImage'] as String? ?? 'assets/images/block_landscape.png',
    port: json['port'] as int? ?? 19132,
  );
  final String id;
  final int rank;
  final String name;
  final List<String> tags;
  final int online;
  final int capacity;
  final String address;
  final String status;
  final String website;
  final String description;
  final String bannerLabel;
  final String bannerImage;
  final int port;
}

class ServerCatalog {
  const ServerCatalog({required this.banner, required this.servers});
  factory ServerCatalog.fromJson(Map<String, dynamic> json) => ServerCatalog(
    banner: json['banner'] as String,
    servers: (json['servers'] as List)
        .map((e) => ServerItem.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
  );
  final String banner;
  final List<ServerItem> servers;
}
