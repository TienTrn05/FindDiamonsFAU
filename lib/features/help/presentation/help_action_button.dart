import '../../../common/widgets/app_text.dart';
import 'package:flutter/material.dart';
import '../../../common/widgets/mining_surface.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class HelpActionButton extends StatelessWidget {
  const HelpActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.light = false,
    this.trailing,
    this.alignLeft = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool light;
  final Widget? trailing;
  final bool alignLeft;

  @override
  Widget build(BuildContext context) => MiningPanel(
    color: light ? AppColors.helpRaised : AppColors.primary,
    borderColor: light ? AppColors.helpBorder : AppColors.accent,
    padding: EdgeInsets.zero,
    child: SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: const PixelBorder(),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              fit: alignLeft ? FlexFit.tight : FlexFit.loose,
              child: AppText(
                label,
                textAlign: alignLeft ? TextAlign.start : TextAlign.center,
                style: AppTextStyles.helpOnDarkHeading.copyWith(
                  color: light ? AppColors.primary : AppColors.cave,
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ],
          ],
        ),
      ),
    ),
  );
}
