import '../../../common/widgets/app_text.dart';
import 'package:flutter/material.dart';
import '../../../common/widgets/landscape_background.dart';
import '../../../common/widgets/resource_view.dart';
import '../../../common/widgets/voxel_character.dart';
import '../../../core/responsive/app_layout.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../bloc/servers_bloc.dart';
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
    widget.repository ?? const JsonServersRepository(),
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
        builder: (context, catalog) => Column(
          children: [
            Material(
              color: AppColors.banner,
              child: InkWell(
                onTap: () => _details(catalog.servers.first),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppText(
                          catalog.banner,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.onPrimaryPixelField,
                        ),
                      ),
                      const SizedBox.square(
                        dimension: 44,
                        child: RotationTransition(
                          turns: AlwaysStoppedAnimation(-.04),
                          child: VoxelCharacter(headOnly: true),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => RefreshIndicator(
                  onRefresh: _bloc.load,
                  child: ListView.builder(
                    key: const PageStorageKey('server-list'),
                    itemCount: catalog.servers.length,
                    itemBuilder: (context, index) => _ServerCard(
                      server: catalog.servers[index],
                      compact: AppLayout.compact(constraints.maxWidth),
                      onTap: () => _details(catalog.servers[index]),
                    ),
                  ),
                ),
              ),
            ),
          ],
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

  Widget get _count => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      AppText(
        '${server.online}/${server.capacity}',
        style: AppTextStyles.serverCount,
      ),
      const SizedBox(width: AppSpacing.sm),
      Icon(
        Icons.adjust,
        size: 16,
        color: server.status == 'online' ? AppColors.online : AppColors.offline,
      ),
    ],
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
    child: Material(
      color: AppColors.serverSurface,
      child: InkWell(
        key: ValueKey('server-${server.id}'),
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        focusColor: Colors.transparent,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),

        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.action, width: 3.5),
            ),
          ),
          padding: const EdgeInsets.only(top: 46),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 70,
                  alignment: Alignment.center,
                  color: AppColors.rank,
                  child: AppText('#${server.rank}', style: AppTextStyles.rank),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AppText(server.name, style: AppTextStyles.serverTitle),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: server.tags
                              .map(
                                (tag) => DecoratedBox(
                                  decoration: const BoxDecoration(
                                    color: AppColors.chipSurface,
                                    borderRadius: AppRadii.pill,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.xs,
                                      vertical: AppSpacing.xs,
                                    ),
                                    child: AppText(
                                      tag,
                                      style: AppTextStyles.tag,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        if (compact) ...[
                          const SizedBox(height: AppSpacing.sm),
                          _count,
                        ],
                      ],
                    ),
                  ),
                ),
                if (!compact)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: Center(child: _count),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
