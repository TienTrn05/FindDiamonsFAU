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
          onReveal: (count) => controller.reveal(record.id, count),
          onFoundChanged: (index, found) =>
              controller.setFound(record.id, index, found),
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

  Widget _coordinate(String axis, int value, double maxWidth) => ConstrainedBox(
    constraints: BoxConstraints(maxWidth: maxWidth),
    child: Text(
      '$axis: $value',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.historyCard,
    ),
  );

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.oreRow,
    shape: RoundedRectangleBorder(
      borderRadius: AppRadii.card,
      side: const BorderSide(color: AppColors.oreRowBorder, width: 3),
    ),
    clipBehavior: Clip.antiAlias,
    child: ListTile(
      key: ValueKey('history-${record.id}'),
      onTap: onTap,
      isThreeLine: true,
      titleAlignment: ListTileTitleAlignment.center,
      contentPadding: const EdgeInsets.all(AppSpacing.md),

      leading: Semantics(
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

      title: LayoutBuilder(
        builder: (context, constraints) => Table(
          columnWidths: const {0: FlexColumnWidth(), 1: IntrinsicColumnWidth()},
          defaultVerticalAlignment: TableCellVerticalAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            TableRow(
              children: [
                const AppText('Seed:', style: AppTextStyles.historyCard),
                _coordinate('X', record.playerX, constraints.maxWidth * .45),
              ],
            ),
            TableRow(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    top: AppSpacing.xs,
                    right: AppSpacing.sm,
                  ),
                  child: Text(
                    record.seed,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.fieldValue,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: _coordinate(
                    'Z',
                    record.playerZ,
                    constraints.maxWidth * .45,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: AppText(
          'Version: ${record.version}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.historyCard,
        ),
      ),

      trailing: const Icon(
        Icons.chevron_right,
        size: 26,
        color: AppColors.text,
      ),
    ),
  );
}
