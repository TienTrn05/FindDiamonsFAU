import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../common/widgets/app_text.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/map_catalog.dart';

/// Seeds show their world preview and description directly in the list.
class SeedMapCard extends StatelessWidget {
  const SeedMapCard({
    super.key,
    required this.item,
    required this.favourite,
    required this.onFavourite,
    this.selectedVersion,
  });

  final MapItem item;
  final bool favourite;
  final VoidCallback onFavourite;
  final String? selectedVersion;

  Future<void> _copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: item.seed!));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: AppText('Seed copied')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final version =
        selectedVersion ?? item.versions.firstOrNull ?? item.subtitle;
    final seedDetails = [
      if (item.seedEdition.isNotEmpty) item.seedEdition.toUpperCase(),
      if (version.isNotEmpty) version,
      if (item.seedCategory.isNotEmpty) item.seedCategory,
    ].join(' · ');
    return Material(
      color: AppColors.oreRow,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.card,
        side: const BorderSide(color: AppColors.oreRowBorder, width: 3),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        key: ValueKey('map-${item.id}'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 2,
            child: item.coverUrl == null
                ? Image.asset(item.cover, fit: BoxFit.cover)
                : Image.network(
                    item.coverUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        Image.asset(item.cover, fit: BoxFit.cover),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppText(item.name, style: AppTextStyles.itemTitle),
                    ),
                    IconButton(
                      key: ValueKey('favourite-${item.id}'),
                      visualDensity: VisualDensity.compact,
                      tooltip: context.tr(
                        favourite ? 'Remove favourite' : 'Add favourite',
                      ),
                      onPressed: onFavourite,
                      icon: Icon(
                        favourite ? Icons.star : Icons.star_border,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                if (item.seed != null)
                  Row(
                    children: [
                      Expanded(
                        child: AppText(
                          'Seed: ${item.seed}',
                          style: AppTextStyles.itemTitle.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      IconButton(
                        key: ValueKey('copy-seed-${item.id}'),
                        visualDensity: VisualDensity.compact,
                        tooltip: context.tr('Copy seed'),
                        onPressed: () => _copy(context),
                        icon: const Icon(
                          Icons.content_paste_outlined,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                if (seedDetails.isNotEmpty) ...[
                  AppText(
                    seedDetails,
                    style: AppTextStyles.itemTitle.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                AppText(
                  item.description,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 16,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
