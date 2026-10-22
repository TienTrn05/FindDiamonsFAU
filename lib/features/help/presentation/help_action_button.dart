import '../../../common/widgets/app_text.dart';
import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: light ? AppColors.helpPanel : AppColors.primary,
      borderRadius: AppRadii.standard,
      boxShadow: const [
        BoxShadow(
          color: AppColors.buttonShadow,
          blurRadius: 8,
          offset: Offset(0, 4),
        ),
      ],
    ),
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
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.standard),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              fit: alignLeft ? FlexFit.tight : FlexFit.loose,
              child: AppText(
                label,
                textAlign: alignLeft ? TextAlign.start : TextAlign.center,
                style: light
                    ? AppTextStyles.helpQuestion
                    : AppTextStyles.helpAction,
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
