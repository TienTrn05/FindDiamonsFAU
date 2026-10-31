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
    this.website = '',
    this.description =
        'Welcome to our community! Explore new worlds, build '
        'with friends and discover your next adventure. Enjoy a choice of '
        'game modes, community events and a friendly place to play. '
        'More server information will be available here soon.',
    this.bannerLabel = 'SKYBLOCK',
    this.bannerImage = 'assets/images/block_landscape.png',
    this.port = 19132,
    String? javaAddress,
    this.javaPort = 25565,
    this.edition = 'bedrock',
    this.bedrockAddress,
    this.isOnline,
    this.playersOnline,
    this.playersMax,
    this.version,
    this.motd,
    this.icon,
    this.joinNote = '',
    this.infoSource = '',
    this.bannerStyle = 'full',
    this.bannerUrl,
    this.javaSupported,
    this.bedrockSupported,
  }) : javaAddress = javaAddress ?? address;
  factory ServerItem.fromJson(Map<String, dynamic> json) => ServerItem(
    id: json['id'] as String,
    rank: json['rank'] as int,
    name: json['name'] as String,
    tags: List<String>.from(json['tags'] as List),
    online: json['online'] as int,
    capacity: json['capacity'] as int,
    address: json['address'] as String,
    status: json['status'] as String,
    website: json['website'] as String? ?? '',
    description:
        json['description'] as String? ??
        'Welcome to our community! Explore new worlds, build with friends '
            'and discover your next adventure. Enjoy a choice of game modes, '
            'community events and a friendly place to play. '
            'More server information will be available here soon.',
    bannerLabel: displayServerBannerText(
      json['bannerLabel'],
      json['name'] as String? ?? 'Minecraft server',
    ),
    bannerImage:
        json['bannerImage'] as String? ?? 'assets/images/block_landscape.png',
    port: json['port'] as int? ?? 19132,
    javaAddress: json['javaAddress'] as String?,
    javaPort: json['javaPort'] as int? ?? 25565,
  );

  factory ServerItem.fromApiJson(
    Map<String, dynamic> json, {
    required int rank,
    Map<String, dynamic>? live,
    Uri? bannerUrl,
  }) {
    final edition = json['edition'] as String? ?? 'bedrock';
    final rawBedrockAddress = json['bedrockAddress'] as String?;
    final rawJavaAddress = json['javaAddress'] as String?;
    final rawAddress = json['address'] as String? ?? '';
    final java = edition.toLowerCase() == 'java';
    final connectionAddress = java
        ? rawJavaAddress ?? rawAddress
        : rawBedrockAddress ?? rawAddress;
    final state = live ?? json;
    final rawOnline = state['online'];
    final isOnline = rawOnline is bool ? rawOnline : null;
    int? count(Object? value) => value is int && value >= 0 ? value : null;
    final playersOnline = isOnline == true
        ? count(state['playersOnline'])
        : null;
    final playersMax = isOnline == true ? count(state['playersMax']) : null;
    final rawBannerUrl = bannerUrl;

    return ServerItem(
      id: json['id'] as String,
      rank: rank,
      name: json['name'] as String,
      tags: List<String>.from(json['tags'] as List? ?? const []),
      online: playersOnline ?? 0,
      capacity: playersMax ?? 0,
      address: connectionAddress,
      status: isOnline == null
          ? 'unknown'
          : isOnline
          ? 'online'
          : 'offline',
      edition: edition,
      bedrockAddress: rawBedrockAddress,
      javaAddress: rawJavaAddress,
      isOnline: isOnline,
      javaSupported: java || (rawJavaAddress?.isNotEmpty ?? false),
      bedrockSupported: !java || (rawBedrockAddress?.isNotEmpty ?? false),
      playersOnline: playersOnline,
      playersMax: playersMax,
      version: state['version'] as String?,
      motd: state['motd'] as String?,
      icon: state['icon'] as String?,
      joinNote: json['joinNote'] as String? ?? '',
      infoSource: json['infoSource'] as String? ?? '',
      website: json['website'] as String? ?? 'https://example.com',
      description: json['description'] as String? ?? '',
      bannerLabel: displayServerBannerText(
        json['banner'],
        json['name'] as String,
      ),
      bannerStyle: json['bannerStyle'] as String? ?? 'full',
      bannerUrl: rawBannerUrl,
      port: java ? 25565 : json['bedrockPort'] as int? ?? 19132,
    );
  }
  final String id;
  final int rank;
  final String name;
  final List<String> tags;
  final int online;
  final int capacity;
  final String address;
  final String status;
  final String edition;
  final String? bedrockAddress;
  final bool? isOnline;
  final int? playersOnline;
  final int? playersMax;
  final String? version;
  final String? motd;
  final String? icon;
  final String joinNote;
  final String infoSource;
  final String bannerStyle;
  final Uri? bannerUrl;
  final bool? javaSupported;
  final bool? bedrockSupported;
  bool get supportsJava => javaSupported ?? edition.toLowerCase() == 'java';
  bool get supportsBedrock =>
      bedrockSupported ?? edition.toLowerCase() == 'bedrock';
  bool? get availability =>
      isOnline ??
      switch (status) {
        'online' => true,
        'offline' => false,
        _ => null,
      };
  int? get currentPlayers => availability == false
      ? null
      : playersOnline ??
            (isOnline == null && status == 'online' ? online : null);
  int? get maximumPlayers => availability == false
      ? null
      : playersMax ??
            (isOnline == null && status == 'online' ? capacity : null);
  final String website;
  final String description;
  final String bannerLabel;
  final String bannerImage;
  final int port;
  final String javaAddress;
  final int javaPort;
}

class ServerCatalog {
  const ServerCatalog({
    required this.banner,
    required this.servers,
    this.liveStatusAvailable = true,
    this.fetchedAt,
  });
  factory ServerCatalog.fromJson(Map<String, dynamic> json) => ServerCatalog(
    banner: displayServerBannerText(json['banner'], 'Minecraft servers'),
    servers: (json['servers'] as List)
        .map((e) => ServerItem.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
  );
  final String banner;
  final List<ServerItem> servers;
  final bool liveStatusAvailable;
  final DateTime? fetchedAt;
}

String displayServerBannerText(Object? value, String fallback) {
  if (value is! String) return fallback;
  final text = value.trim();
  if (text.isEmpty ||
      text.startsWith('/') ||
      text.contains('/api/') ||
      text.startsWith('http://') ||
      text.startsWith('https://') ||
      RegExp(
        r'\.(png|jpe?g|gif|svg|webp)(\?|$)',
        caseSensitive: false,
      ).hasMatch(text)) {
    return fallback;
  }
  return text;
}
