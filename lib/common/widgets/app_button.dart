import 'app_text.dart';
import 'package:flutter/material.dart';

import '../../core/responsive/app_layout.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'mining_surface.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.gradient = false,
    this.pixel = false,
    this.backgroundColor = AppColors.primary,
    this.shadow = true,
    this.leading,
    this.trailing,
    this.textStyle,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool gradient;
  final bool pixel;
  final Color backgroundColor;
  final bool shadow;
  final Widget? leading;
  final Widget? trailing;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: onPressed == null ? .45 : 1,
    child: DecoratedBox(
      decoration: ShapeDecoration(
        shape: PixelBorder(
          side: BorderSide(
            color: Color.lerp(backgroundColor, AppColors.cave, .35)!,
            width: 2,
          ),
        ),
        color: backgroundColor,
        gradient: gradient
            ? const LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
              )
            : null,
        shadows: shadow
            ? const [
                BoxShadow(
                  color: AppColors.buttonShadow,
                  offset: Offset(0, 5),
                  blurRadius: 8,
                ),
              ]
            : null,
      ),
      child: SizedBox(
        width: double.infinity,
        child: TextButton(
          style: TextButton.styleFrom(
            foregroundColor: backgroundColor == AppColors.primary
                ? AppColors.cave
                : AppColors.onPrimary,
            disabledForegroundColor: AppColors.onPrimary,
            minimumSize: const Size.fromHeight(AppLayout.buttonMinHeight),
            shape: const PixelBorder(),
          ),
          onPressed: onPressed,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.sm),
              ],
              Flexible(
                child: AppText(
                  label,
                  textAlign: TextAlign.center,
                  style:
                      (textStyle ??
                              (pixel
                                  ? AppTextStyles.pixelButton.copyWith(
                                      fontSize: 17,
                                    )
                                  : AppTextStyles.button.copyWith(
                                      fontSize: 16,
                                    )))
                          .copyWith(
                            color: backgroundColor == AppColors.gold
                                ? AppColors.goldPanel
                                : backgroundColor == AppColors.primary
                                ? AppColors.cave
                                : AppColors.onPrimary,
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
    ),
  );
}
