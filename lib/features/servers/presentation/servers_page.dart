import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../common/widgets/app_text.dart';
import '../../../common/widgets/landscape_background.dart';
import '../../../common/widgets/resource_view.dart';
import '../../../core/monetization/app_monetization.dart';
import '../../../core/network/api_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../bloc/servers_bloc.dart';
import '../data/api_servers_repository.dart';
import '../data/servers_repository.dart';
import '../models/server_catalog.dart';
import '../../skins/models/skin_item.dart';
import 'server_info_page.dart';
import 'server_profile_header.dart';
import 'server_username_dialog.dart';

class ServersPage extends StatefulWidget {
  const ServersPage({super.key, this.repository, this.selectedSkin});
  final ServersRepository? repository;
  final SkinItem? selectedSkin;
  @override
  State<ServersPage> createState() => _ServersPageState();
}

class _ServersPageState extends State<ServersPage> {
  static const _usernameKey = 'minecraft_username';
  static const _autoReloadInterval = Duration(minutes: 10);

  late final ServersBloc _bloc = ServersBloc(
    widget.repository ?? ApiServersRepository(),
  )..load();

  Timer? _autoReloadTimer;
  String? _minecraftUsername;
  bool _reloading = false;

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _scheduleAutoReload();
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

  Future<void> _openServerListing() async {
    final url = ApiConfig.baseUri.resolve('/mcstat.html');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication) &&
        mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: AppText('Unable to open the server listing page.'),
        ),
      );
    }
  }

  void _scheduleAutoReload() {
    _autoReloadTimer?.cancel();
    _autoReloadTimer = Timer(_autoReloadInterval, _autoReload);
  }

  bool get _canAutoReload =>
      mounted &&
      TickerMode.of(context) &&
      (ModalRoute.of(context)?.isCurrent ?? true) &&
      MediaQuery.viewInsetsOf(context).bottom == 0 &&
      (WidgetsBinding.instance.lifecycleState == null ||
          WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed);

  Future<void> _autoReload() async {
    if (!_canAutoReload || _reloading || _bloc.loading) {
      _scheduleAutoReload();
      return;
    }

    _reloading = true;
    try {
      final access = MonetizationScope.maybeOf(context);
      if (access != null && !access.isPro) {
        await access.maybeShowInterstitial(canShow: () => _canAutoReload);
      }
      if (mounted && _canAutoReload) await _bloc.load();
    } finally {
      _reloading = false;
      if (mounted) _scheduleAutoReload();
    }
  }

  @override
  void dispose() {
    _autoReloadTimer?.cancel();
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
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.banner,
    child: SafeArea(
      bottom: false,
      child: Column(
        children: [
          ServerProfileHeader(
            username: _minecraftUsername,
            selectedSkin: widget.selectedSkin,
            onTap: _editUsername,
          ),
          Expanded(
            child: LandscapeBackground(
              washed: true,
              child: ResourceView<ServerCatalog>(
                controller: _bloc,
                builder: (context, catalog) => LayoutBuilder(
                  builder: (context, constraints) => ListView.builder(
                    key: const PageStorageKey('server-list'),
                    padding: const EdgeInsets.only(bottom: 10),
                    itemCount: catalog.servers.length + 1,
                    itemBuilder: (context, index) {
                      if (index == catalog.servers.length) {
                        return _ServerListingLink(
                          compact: constraints.maxWidth < 600,
                          onTap: _openServerListing,
                        );
                      }
                      final server = catalog.servers[index];
                      return _ServerCard(
                        server: server,
                        compact: constraints.maxWidth < 600,
                        narrow: constraints.maxWidth < 380,
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

class _ServerCard extends StatelessWidget {
  const _ServerCard({
    required this.server,
    required this.compact,
    required this.narrow,
    required this.onTap,
  });
  final ServerItem server;
  final bool compact;
  final bool narrow;
  final VoidCallback onTap;

  bool get _hasRecordedStatus =>
      server.status == 'online' || server.status == 'offline';

  int? get _online =>
      server.playersOnline ?? (_hasRecordedStatus ? server.online : null);

  int? get _capacity =>
      server.playersMax ?? (_hasRecordedStatus ? server.capacity : null);

  Widget _count() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      AppText(
        _online != null && _capacity != null ? '$_online/$_capacity' : '—',
        style: TextStyle(
          fontFamily: 'Roboto',
          color: AppColors.text,
          fontSize: compact ? 14 : 19,
          fontWeight: FontWeight.w500,
        ),
      ),
      SizedBox(width: compact ? 8 : 12),
      DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _statusColor,
          boxShadow: [
            BoxShadow(
              color: _statusColor.withValues(alpha: .3),
              blurRadius: 0,
              spreadRadius: compact ? 2 : 3,
            ),
          ],
        ),
        child: SizedBox.square(dimension: compact ? 10 : 13),
      ),
    ],
  );

  Color get _statusColor => switch (server.isOnline ??
      (server.status == 'online'
          ? true
          : server.status == 'offline'
          ? false
          : null)) {
    true => AppColors.online,
    false => AppColors.offline,
    null => AppColors.textMuted,
  };

  Widget _banner() {
    final url = server.bannerUrl;
    final fallback = ColoredBox(
      color: AppColors.serverHero,
      child: Center(
        child: AppText(
          server.bannerLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.onPrimary,
            fontSize: compact ? 16 : 21,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
    final bundledBanner = Image.asset(
      server.bannerImage,
      fit: BoxFit.cover,
      width: double.infinity,
      errorBuilder: (_, _, _) => fallback,
    );
    return SizedBox(
      height: compact ? 34 : 76,
      width: double.infinity,
      child: url == null
          ? bundledBanner
          : Image.network(
              url.toString(),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => bundledBanner,
            ),
    );
  }

  Widget _tag(String text) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.chipSurface,
      borderRadius: AppRadii.pill,
    ),
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 12,
        vertical: compact ? 3 : 7,
      ),
      child: AppText(
        text,
        style: TextStyle(
          fontFamily: 'Roboto',
          color: AppColors.text,
          fontSize: compact ? 11 : 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: compact ? 13 : 29),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        key: ValueKey('server-${server.id}'),
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _banner(),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: compact ? 48 : 110,
                    alignment: Alignment.center,
                    color: AppColors.rank,
                    child: AppText(
                      '#${server.rank}',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        color: AppColors.onPrimary,
                        fontSize: compact ? 20 : 38,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: AppColors.serverSurface,
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 8 : 18,
                        vertical: compact ? 5 : 14,
                      ),
                      child: narrow
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: _name()),
                                    const SizedBox(width: 6),
                                    _count(),
                                  ],
                                ),
                                if (_hasTags) ...[
                                  const SizedBox(height: 5),
                                  _tags(),
                                ],
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _name(),
                                      if (_hasTags) ...[
                                        SizedBox(height: compact ? 6 : 12),
                                        _tags(),
                                      ],
                                    ],
                                  ),
                                ),
                                SizedBox(width: compact ? 6 : 14),
                                _count(),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
            Container(height: compact ? 4 : 6, color: AppColors.action),
          ],
        ),
      ),
    ),
  );

  bool get _hasTags =>
      server.tags.isNotEmpty || server.edition.toLowerCase() == 'java';

  Widget _name() => AppText(
    server.name,
    style: TextStyle(
      fontFamily: 'Roboto',
      color: AppColors.text,
      fontSize: compact ? 14 : 20,
      fontWeight: FontWeight.w700,
    ),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );

  Widget _tags() => Wrap(
    spacing: compact ? 4 : 9,
    runSpacing: compact ? 3 : 7,
    children: [
      for (final tag in server.tags) _tag(tag),
      if (server.edition.toLowerCase() == 'java' &&
          !server.tags.any((tag) => tag.toLowerCase() == 'java'))
        _tag('Java'),
    ],
  );
}

class _ServerListingLink extends StatelessWidget {
  const _ServerListingLink({required this.compact, required this.onTap});

  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: compact ? 4 : 8, bottom: compact ? 8 : 12),
    child: Material(
      color: AppColors.serverHero.withValues(alpha: .45),
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: compact ? 64 : 88,
          width: double.infinity,
          child: Center(
            child: AppText(
              'Own a server? List it here!',
              style: TextStyle(
                fontFamily: 'Roboto',
                color: AppColors.text,
                fontSize: compact ? 16 : 20,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
