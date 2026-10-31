import 'package:flutter/material.dart';
import '../../../common/widgets/mining_surface.dart';

import '../../../common/widgets/app_button.dart';
import '../../../common/widgets/app_text.dart';
import '../../../common/widgets/ore_art.dart';
import '../../../core/models/search_record.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class OreStatusDialog extends StatelessWidget {
  const OreStatusDialog({super.key, required this.position, required this.ore});

  final OrePosition position;
  final Ore ore;

  @override
  Widget build(BuildContext context) => Dialog(
    key: const ValueKey('ore-status-dialog'),
    backgroundColor: AppColors.oreRow,
    surfaceTintColor: AppColors.transparent,
    insetPadding: const EdgeInsets.all(AppSpacing.lg),
    shape: const PixelBorder(
      side: BorderSide(color: AppColors.helpBorder, width: 2),
    ),
    clipBehavior: Clip.antiAlias,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 440),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: AppText(
                      'Ore status',
                      style: AppTextStyles.dialogTitle,
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('close-ore-status'),
                    tooltip: context.tr('Close'),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.oreRowBorder,
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OreIcon(ore: ore, size: 44),
                      const SizedBox(height: AppSpacing.xs),
                      AppText('x${position.count}', style: AppTextStyles.body),
                    ],
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.sm,
                      children: [
                        AppText('X: ${position.x}', style: AppTextStyles.body),
                        AppText('Y: ${position.y}', style: AppTextStyles.body),
                        AppText('Z: ${position.z}', style: AppTextStyles.body),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: AppButton(
                        key: const ValueKey('mark-ore-not-found'),
                        label: 'Not found',
                        backgroundColor: AppColors.helpRaised,
                        shadow: false,
                        textStyle: AppTextStyles.pixelBody,
                        onPressed: () => Navigator.pop(context, false),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: AppButton(
                        key: const ValueKey('mark-ore-found'),
                        label: 'Found',
                        backgroundColor: AppColors.action,
                        shadow: false,
                        textStyle: AppTextStyles.pixelBody,
                        onPressed: () => Navigator.pop(context, true),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
