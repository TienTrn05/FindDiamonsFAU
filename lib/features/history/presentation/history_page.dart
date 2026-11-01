import '../../../common/widgets/app_text.dart';
import 'package:flutter/material.dart';
import '../../../common/widgets/mining_surface.dart';
import '../../../common/widgets/mining_components.dart';
import '../../../common/widgets/game_header.dart';
import '../../../common/widgets/ore_display.dart';
import '../../../common/widgets/mining_neon_panel.dart';
import '../../../core/theme/mining_style.dart';
import '../../../common/widgets/resource_view.dart';
import '../../digging/presentation/found_ores_page.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/monetization/app_monetization.dart';
import '../../../core/theme/app_text_styles.dart';
import '../bloc/history_bloc.dart';
import '../models/history_data.dart';
import '../../../core/models/search_record.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({
    super.key,
    required this.controller,
    required this.onGoPro,
    required this.onHelp,
    this.onFind,
  });
  final HistoryBloc controller;
  final VoidCallback onGoPro;
  final VoidCallback onHelp;
  final VoidCallback? onFind;

  Future<void> _remove(BuildContext context, String id) async {
    try {
      await controller.remove(id);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: AppText('History could not be saved.')),
        );
      }
    }
  }

  void _open(BuildContext context, SearchRecord record) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => FoundOresPage(
          monetization: MonetizationScope.maybeOf(context),
          record: record,
          onGoPro: onGoPro,
          onHelp: onHelp,
          showLoading: false,
          onReveal: (count) => controller.reveal(record.id, count),
          onFoundChanged: (index, found) =>
              controller.setFound(record.id, index, found),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MiningBackground(
    vivid: true,
    child: Column(
      children: [
        const GameHeader(
          title: 'History',
          contentHeight: 82,
          subtitle: 'Your discoveries, all in one place.',
          icon: Icons.menu_book_outlined,
        ),
        Expanded(
          child: ResourceView<HistoryData>(
            controller: controller,
            builder: (context, data) {
              if (data.searches.isEmpty) {
                return MiningEmptyState(
                  title: data.emptyMessage,
                  icon: Icons.explore_outlined,
                  message: 'Start a search to build your expedition log.',
                  action: onFind == null ? null : 'Find Ore',
                  onAction: onFind,
                );
              }
              return ListView.separated(
                key: const PageStorageKey('history-list'),
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                itemCount: data.searches.length,
                separatorBuilder: (_, _) => const SizedBox(height: 9),
                itemBuilder: (context, index) {
                  final record = data.searches[index];
                  return _HistoryCard(
                    record: record,
                    onTap: () => _open(context, record),
                    onDelete: () => _remove(context, record.id),
                  );
                },
              );
            },
          ),
        ),
      ],
    ),
  );
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({
    required this.record,
    required this.onTap,
    required this.onDelete,
  });
  final SearchRecord record;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => MiningNeonPanel(
    accent: MiningStyle.oreAccent(record.oreId),
    rail: true,
    padding: const EdgeInsets.fromLTRB(10, 8, 9, 8),
    child: InkWell(
      key: ValueKey('history-${record.id}'),
      onTap: onTap,
      child: Row(
        children: [
          Semantics(
            label: context.tr(record.oreName),
            image: true,
            child: OreDisplay(id: record.oreId, size: 66),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  record.oreName,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onPrimary,
                  ),
                ),
                AppText(
                  'Version: ${record.version}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 11,
                    color: AppColors.caveMuted,
                  ),
                ),
                Row(
                  children: [
                    AppText(
                      'Seed:',
                      style: AppTextStyles.body.copyWith(
                        fontSize: 11,
                        color: AppColors.caveMuted,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        record.seed,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 11,
                          color: AppColors.caveMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: MiningTag(
                        'X: ${record.playerX}',
                        icon: Icons.my_location,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: MiningTag(
                        'Z: ${record.playerZ}',
                        icon: Icons.my_location,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              SizedBox.square(
                dimension: 34,
                child: IconButton(
                  key: ValueKey('history-delete-${record.id}'),
                  tooltip: context.tr('Delete search'),
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  icon: const Icon(
                    Icons.delete_forever,
                    color: AppColors.caveMuted,
                    size: 21,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox.square(
                dimension: 32,
                child: Material(
                  color: AppColors.primary,
                  shape: const PixelBorder(step: 4),
                  child: InkWell(
                    onTap: onTap,
                    child: const Icon(
                      Icons.chevron_right,
                      color: AppColors.cave,
                      size: 27,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
