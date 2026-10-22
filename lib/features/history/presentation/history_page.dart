import '../../../common/widgets/app_text.dart';
import 'package:flutter/material.dart';
import '../../../common/widgets/landscape_background.dart';
import '../../../common/widgets/ore_art.dart';
import '../../../common/widgets/resource_view.dart';
import '../../digging/presentation/found_ores_page.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/monetization/app_monetization.dart';
import '../../../core/theme/app_spacing.dart';
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
  });
  final HistoryBloc controller;
  final VoidCallback onGoPro;
  final VoidCallback onHelp;

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
          showAllInitially: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => LandscapeBackground(
    washed: true,
    child: SafeArea(
      bottom: false,
      child: ResourceView<HistoryData>(
        controller: controller,
        builder: (context, data) {
          if (data.searches.isEmpty) {
            return Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.lg),
                child: ColoredBox(
                  color: AppColors.heroScrim,
                  child: SizedBox(
                    width: double.infinity,
                    child: AppText(
                      data.emptyMessage,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body,
                    ),
                  ),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.sm),
            itemCount: data.searches.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
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
  Widget build(BuildContext context) => Material(
    color: AppColors.oreRow,
    borderRadius: AppRadii.card,
    child: InkWell(
      key: ValueKey('history-${record.id}'),
      borderRadius: AppRadii.card,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.oreRowBorder, width: 3),
          borderRadius: AppRadii.card,
        ),
        child: Row(
          children: [
            Semantics(
              label: context.tr(record.oreName),
              image: true,
              child: OreIcon(
                ore: Ore.values.firstWhere(
                  (ore) => ore.name == record.oreId,
                  orElse: () => Ore.diamond,
                ),
                size: 44,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppText(
                              'Seed:',
                              style: AppTextStyles.itemTitle,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              record.seed,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.itemTitle.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Flexible(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'X: ${record.playerX}',
                              style: AppTextStyles.pixelBodyLarge,
                            ),
                            Text(
                              'Z: ${record.playerZ}',
                              style: AppTextStyles.pixelBodyLarge,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppText(
                    'Version: ${record.version}',
                    style: AppTextStyles.pixelBodyLarge,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Column(
              children: [
                const Icon(Icons.chevron_right, size: 26),
                IconButton(
                  tooltip: context.tr('Delete search'),
                  visualDensity: VisualDensity.compact,
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
