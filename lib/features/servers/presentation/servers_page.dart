import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../common/widgets/app_text.dart';
import '../../../common/widgets/mining_neon_panel.dart';
import '../../../core/theme/mining_style.dart';
import '../../../common/widgets/mining_surface.dart';
import '../../../common/widgets/game_header.dart';
import '../../../core/theme/app_text_styles.dart';
import 'server_banner.dart';
import 'server_status.dart';
import '../../../common/widgets/resource_view.dart';
import '../../../core/monetization/app_monetization.dart';
import '../../../core/theme/app_colors.dart';
import '../bloc/servers_bloc.dart';
import '../data/api_servers_repository.dart';
import '../data/servers_repository.dart';
import '../data/server_media_cache.dart';
import '../models/server_catalog.dart';
import '../../skins/models/skin_item.dart';
import 'server_info_page.dart';
import 'server_profile_header.dart';
import 'server_username_dialog.dart';

class ServersPage extends StatefulWidget {
  const ServersPage({
    super.key,
    this.repository,
    this.selectedSkin,
    this.initialCatalog,
    this.prepareCatalog,
  });
  final ServersRepository? repository;
  final SkinItem? selectedSkin;
  final ServerCatalog? initialCatalog;
  final Future<void> Function(ServerCatalog)? prepareCatalog;
  @override
  State<ServersPage> createState() => _ServersPageState();
}

class _ServersPageState extends State<ServersPage> with WidgetsBindingObserver {
  static const _usernameKey = 'minecraft_username';

  late final _repository = widget.repository ?? ApiServersRepository();
  late final ServersBloc _bloc = ServersBloc(
    _repository,
    initialData: widget.initialCatalog,
    prepare: widget.prepareCatalog ?? prepareServerImages,
  );
  Timer? _syncTimer;

  String? _minecraftUsername;

  @override
  void initState() {
    super.initState();
    _loadUsername();
    WidgetsBinding.instance.addObserver(this);
    if (_bloc.data == null) {
      _bloc.load().whenComplete(_scheduleSync);
    } else {
      _scheduleSync();
    }
  }

  void _scheduleSync() {
    _syncTimer?.cancel();
    if (!mounted || _repository is! RefreshableServersRepository) return;
    _syncTimer = Timer(const Duration(seconds: 60), () async {
      final state = WidgetsBinding.instance.lifecycleState;
      if (state == null || state == AppLifecycleState.resumed) {
        await _bloc.checkForUpdates();
      }
      _scheduleSync();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Repository load observes its TTL, so a quick resume needs no request.
      _bloc.checkForUpdates();
      _scheduleSync();
    }
  }

  Future<void> _loadUsername() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() => _minecraftUsername = preferences.getString(_usernameKey));
    } catch (error) {
      debugPrint('Minecraft username storage unavailable: $error');
    }
  }

  Future<void> _editUsername() async {
    final username = await showDialog<String>(
      context: context,
      barrierColor: const Color(0xB3000000),
      builder: (_) => ServerUsernameDialog(username: _minecraftUsername),
    );
    if (!mounted || username == null) return;
    final cleaned = username.trim();
    setState(() => _minecraftUsername = cleaned.isEmpty ? null : cleaned);
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = cleaned.isEmpty
          ? await preferences.remove(_usernameKey)
          : await preferences.setString(_usernameKey, cleaned);
      if (!saved) throw StateError('Username could not be saved');
    } catch (error) {
      debugPrint('Minecraft username could not be saved: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: AppText('Unable to save your username.')),
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncTimer?.cancel();
    _bloc.dispose();
    super.dispose();
  }

  void _details(ServerItem server) {
    final access = MonetizationScope.maybeOf(context);
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        settings: RouteSettings(name: '/servers/${server.id}'),
        builder: (_) => access == null
            ? ServerInfoPage(server: server)
            : MonetizationScope(
                controller: access,
                child: ServerInfoPage(server: server),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MiningBackground(
    vivid: true,
    child: SafeArea(
      bottom: false,
      child: Column(
        children: [
          GameHeader(
            title: 'Servers',
            subtitle: 'Tap a server to join.',
            icon: Icons.dns_outlined,
            contentHeight: 82,
            trailing: SizedBox(
              width: 40,
              child: ServerProfileHeader(
                compact: true,
                username: _minecraftUsername,
                selectedSkin: widget.selectedSkin,
                onTap: _editUsername,
              ),
            ),
          ),
          ListenableBuilder(
            listenable: _bloc,
            builder: (context, _) => _bloc.data?.liveStatusAvailable == false
                ? Padding(
                    key: const ValueKey('server-status-unavailable'),
                    padding: const EdgeInsets.fromLTRB(14, 5, 14, 0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.cloud_off,
                          size: 15,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: AppText(
                            'Live status unavailable.',
                            style: AppTextStyles.body.copyWith(
                              fontSize: 11,
                              color: AppColors.caveMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: MiningBackground(
              vivid: true,
              child: ResourceView<ServerCatalog>(
                controller: _bloc,
                builder: (context, catalog) => LayoutBuilder(
                  builder: (context, constraints) => ListView.builder(
                    physics: const ClampingScrollPhysics(),
                    key: const PageStorageKey('server-list'),
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                    itemCount: catalog.servers.length,
                    findChildIndexCallback: (key) {
                      if (key is! ValueKey<String>) return null;
                      final index = catalog.servers.indexWhere(
                        (server) => 'server-row-${server.id}' == key.value,
                      );
                      return index < 0 ? null : index;
                    },
                    itemBuilder: (context, index) {
                      final server = catalog.servers[index];
                      return _RetainedServerCard(
                        key: ValueKey('server-row-${server.id}'),
                        server: server,
                        compact: constraints.maxWidth < 430,
                        onTap: () => _details(server),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// The catalog is small (20 servers). Retain only rows that have been built,
// including their Image state, instead of restarting GIFs on every scroll back.
class _RetainedServerCard extends StatefulWidget {
  const _RetainedServerCard({
    super.key,
    required this.server,
    required this.compact,
    required this.onTap,
  });
  final ServerItem server;
  final bool compact;
  final VoidCallback onTap;
  @override
  State<_RetainedServerCard> createState() => _RetainedServerCardState();
}

class _RetainedServerCardState extends State<_RetainedServerCard>
    with AutomaticKeepAliveClientMixin {
  late Widget _card = _createCard();
  Widget _createCard() => _ServerCard(
    server: widget.server,
    compact: widget.compact,
    onTap: () => widget.onTap(),
  );

  @override
  bool get wantKeepAlive => true;

  @override
  void didUpdateWidget(covariant _RetainedServerCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.server, widget.server) ||
        oldWidget.compact != widget.compact) {
      _card = _createCard();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return _card;
  }
}

class _ServerCard extends StatelessWidget {
  const _ServerCard({
    required this.server,
    required this.compact,
    required this.onTap,
  });
  final ServerItem server;
  final bool compact;
  final VoidCallback onTap;

  Widget _count() => ServerStatus(server: server);

  Widget _tag(String text) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.chipSurface,
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: AppColors.accent),
    ),
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: AppText(
        text,
        style: TextStyle(
          fontFamily: 'Roboto',
          color: AppColors.text,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: MiningNeonPanel(
      accent: MiningStyle
          .serverAccents[(server.rank - 1) % MiningStyle.serverAccents.length],
      rail: true,
      padding: EdgeInsets.zero,
      child: InkWell(
        key: ValueKey('server-${server.id}'),
        onTap: onTap,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 44,
                child: Center(
                  child: AppText(
                    '#${server.rank}',
                    style: AppTextStyles.pixelTitle.copyWith(
                      fontSize: 20,
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ServerBanner(server: server),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 3, 8, 7),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            server.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body.copyWith(
                              fontSize: 14,
                              height: 1.2,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Wrap(
                                  spacing: 5,
                                  runSpacing: 5,
                                  children: [
                                    for (final tag in server.tags) _tag(tag),
                                    if (server.supportsJava &&
                                        !server.tags.any(
                                          (tag) => tag.toLowerCase().contains(
                                            'java',
                                          ),
                                        ))
                                      _tag('Java'),
                                    if (server.supportsBedrock &&
                                        !server.tags.any(
                                          (tag) => tag.toLowerCase().contains(
                                            'bedrock',
                                          ),
                                        ))
                                      _tag('Bedrock'),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              _count(),
                              const SizedBox(width: 6),
                              SizedBox.square(
                                dimension: 28,
                                child: Material(
                                  color: AppColors.primary,
                                  shape: const PixelBorder(step: 4),
                                  child: InkWell(
                                    onTap: onTap,
                                    child: const Icon(
                                      Icons.chevron_right,
                                      color: AppColors.cave,
                                      size: 24,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
