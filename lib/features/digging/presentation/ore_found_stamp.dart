import 'package:flutter/material.dart';

import '../../../common/widgets/app_text.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class OreFoundStamp extends StatelessWidget {
  const OreFoundStamp({super.key});

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Transform.rotate(
      angle: -.13,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.oreStampInk, width: 2),
          borderRadius: AppRadii.small,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 2,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.oreStampInk),
            borderRadius: AppRadii.small,
          ),
          child: Text(
            context.tr('Found').toUpperCase(),
            semanticsLabel: context.tr('Found'),
            style: AppTextStyles.oreStamp,
            maxLines: 1,
          ),
        ),
      ),
    ),
  );
}
