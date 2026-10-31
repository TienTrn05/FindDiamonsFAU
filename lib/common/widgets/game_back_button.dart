import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'app_text.dart';
import 'mining_surface.dart';

/// One back control for every routed screen; navigation remains with the caller.
class GameBackButton extends StatelessWidget {
  const GameBackButton({super.key, required this.onPressed, this.size = 48});
  final VoidCallback? onPressed;
  final double size;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: context.tr('Back'),
    child: SizedBox.square(
      dimension: size,
      child: MiningPanel(
        color: AppColors.helpSurface,
        borderColor: AppColors.helpBorder,
        vivid: true,
        padding: EdgeInsets.zero,
        child: IconButton(
          onPressed: onPressed,
          padding: EdgeInsets.zero,
          constraints: BoxConstraints.tightFor(width: size, height: size),
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.onPrimary,
            size: 27,
          ),
        ),
      ),
    ),
  );
}
