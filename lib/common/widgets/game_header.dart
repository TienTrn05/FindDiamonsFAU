import 'game_back_button.dart';
import 'package:flutter/material.dart';
import '../../core/responsive/app_layout.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_text.dart';
import 'mining_surface.dart';
import 'mining_neon_panel.dart';

class GameHeader extends StatelessWidget {
  const GameHeader({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
    this.subtitle,
    this.icon,
    this.contentHeight = AppLayout.gameHeaderHeight,
  });
  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onBack;
  final Widget? trailing;
  final double contentHeight;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: contentHeight + MediaQuery.paddingOf(context).top,
    child: MiningBackground(
      vivid: true,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.helpBorder)),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                if (onBack != null) ...[
                  SizedBox(
                    width: 48,
                    child: GameBackButton(
                      key: const ValueKey('game-header-back'),
                      size: 48,
                      onPressed: onBack,
                    ),
                  ),
                  const SizedBox(width: 12),
                ] else if (icon != null) ...[
                  MiningNeonPanel(
                    padding: const EdgeInsets.all(12),
                    child: Icon(icon, color: AppColors.primary, size: 30),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        title,
                        style: AppTextStyles.gameHeader.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: contentHeight < 70
                              ? 21
                              : contentHeight < 80
                              ? 25
                              : 27,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 6),
                        AppText(
                          subtitle!,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.caveMuted,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
