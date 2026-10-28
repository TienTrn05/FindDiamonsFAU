import 'app_text.dart';
import 'package:flutter/material.dart';
import '../../core/responsive/app_layout.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'ore_art.dart';

class GameHeader extends StatelessWidget {
  const GameHeader({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
    this.contentHeight = AppLayout.gameHeaderHeight,
  });
  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final double contentHeight;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: contentHeight + MediaQuery.paddingOf(context).top,
    child: OreBackground(
      diamondOnly: true,
      child: Stack(
        children: [
          const Positioned.fill(child: ColoredBox(color: AppColors.scrim)),
          SafeArea(
            bottom: false,
            child: SizedBox(
              height: contentHeight,
              width: double.infinity,
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: onBack == null && trailing == null
                        ? AppSpacing.md
                        : AppLayout.navigationExtent,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AppText(title, style: AppTextStyles.gameHeader),
                  ),
                ),
              ),
            ),
          ),
          if (onBack != null)
            Positioned.fill(
              child: SafeArea(
                bottom: false,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    key: const ValueKey('game-header-back'),
                    tooltip: context.tr('Back'),
                    onPressed: onBack,
                    icon: const Icon(
                      Icons.arrow_back,
                      color: AppColors.onPrimary,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
          if (trailing != null)
            Positioned.fill(
              child: SafeArea(
                bottom: false,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: trailing!,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
