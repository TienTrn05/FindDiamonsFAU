import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../common/widgets/app_text.dart';
import '../../../common/widgets/landscape_background.dart';
import '../../../common/widgets/resource_view.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../bloc/servers_bloc.dart';
import '../data/api_servers_repository.dart';
import '../data/servers_repository.dart';
import '../models/server_catalog.dart';
import 'server_info_page.dart';

class ServersPage extends StatefulWidget {
  const ServersPage({super.key, this.repository});
  final ServersRepository? repository;
  @override
  State<ServersPage> createState() => _ServersPageState();
}

class _ServersPageState extends State<ServersPage> {
  late final ServersBloc _bloc = ServersBloc(
    widget.repository ?? ApiServersRepository(),
  )..load();
  @override
  void dispose() {
    _bloc.dispose();
    super.dispose();
  }

  void _details(ServerItem server) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      settings: RouteSettings(name: '/servers/${server.id}'),
      builder: (_) => ServerInfoPage(server: server),
    ),
  );

  @override
  Widget build(BuildContext context) => LandscapeBackground(
    washed: true,
    child: SafeArea(
      bottom: false,
      child: ResourceView<ServerCatalog>(
        controller: _bloc,
        builder: (context, catalog) => ColoredBox(
          color: const Color(0xFFE5E7E4),
          child: LayoutBuilder(
            builder: (context, constraints) => RefreshIndicator(
              onRefresh: _bloc.load,
              child: ListView.builder(
                key: const PageStorageKey('server-list'),
                padding: EdgeInsets.fromLTRB(
                  constraints.maxWidth < 430 ? 8 : 16,
                  10,
                  constraints.maxWidth < 430 ? 8 : 16,
                  10,
                ),
                itemCount: catalog.servers.length,
                itemBuilder: (context, index) => _ServerCard(
                  server: catalog.servers[index],
                  compact: constraints.maxWidth < 430,
                  onTap: () => _details(catalog.servers[index]),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
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

  Widget _count() => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      AppText(
        server.playersOnline != null && server.playersMax != null
            ? '${server.playersOnline}/${server.playersMax}'
            : '—',
        style: TextStyle(
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

  Color get _statusColor => switch (server.isOnline) {
    true => AppColors.online,
    false => AppColors.offline,
    null => AppColors.textMuted,
  };

  Widget _banner() {
    final url = server.bannerUrl;
    if (url == null) {
      return Container(
        height: compact ? 52 : 76,
        alignment: Alignment.center,
        color: AppColors.serverHero,
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
      );
    }
    final fallback = Image.asset(
      server.bannerImage,
      fit: BoxFit.cover,
      width: double.infinity,
    );
    if (url.path.toLowerCase().endsWith('.svg')) {
      return SizedBox(
        height: compact ? 52 : 76,
        width: double.infinity,
        child: SvgPicture.network(
          url.toString(),
          fit: BoxFit.cover,
          placeholderBuilder: (_) => fallback,
        ),
      );
    }
    return Image.network(
      url.toString(),
      height: compact ? 52 : 76,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
    );
  }

  Widget _tag(String text) => DecoratedBox(
    decoration: BoxDecoration(
      color: AppColors.chipSurface,
      borderRadius: AppRadii.pill,
    ),
    child: Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 12,
        vertical: compact ? 5 : 7,
      ),
      child: AppText(
        text,
        style: TextStyle(
          color: AppColors.text,
          fontSize: compact ? 12 : 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: compact ? AppSpacing.xl : AppSpacing.xxl),
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
                    width: compact ? 72 : 110,
                    alignment: Alignment.center,
                    color: AppColors.rank,
                    child: AppText(
                      '#${server.rank}',
                      style: TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: compact ? 28 : 38,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: AppColors.serverSurface,
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 12 : 18,
                        vertical: compact ? 10 : 14,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: AppText(
                                  server.name,
                                  style: TextStyle(
                                    color: AppColors.text,
                                    fontSize: compact ? 16 : 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              SizedBox(width: compact ? 8 : 14),
                              _count(),
                            ],
                          ),
                          if (server.tags.isNotEmpty ||
                              server.edition.toLowerCase() == 'java') ...[
                            SizedBox(height: compact ? 8 : 12),
                            Wrap(
                              spacing: compact ? 6 : 9,
                              runSpacing: compact ? 5 : 7,
                              children: [
                                for (final tag in server.tags) _tag(tag),
                                if (server.edition.toLowerCase() == 'java' &&
                                    !server.tags.any(
                                      (tag) => tag.toLowerCase() == 'java',
                                    ))
                                  _tag('Java'),
                              ],
                            ),
                          ],
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
}
