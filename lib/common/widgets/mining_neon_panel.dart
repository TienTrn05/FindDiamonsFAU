import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'mining_surface.dart';

/// Dark stone panels with a mineral-colored edge and a soft outer glow.
class MiningNeonPanel extends StatelessWidget {
  const MiningNeonPanel({
    super.key,
    required this.child,
    this.accent = AppColors.primary,
    this.padding = const EdgeInsets.all(12),
    this.onTap,
    this.rail = false,
    this.glow = true,
    this.emphasized = false,
  });
  final Widget child;
  final Color accent;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool rail;
  final bool glow;
  final bool emphasized;
  @override
  Widget build(BuildContext context) => Container(
    decoration: ShapeDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color.lerp(AppColors.cavePanel, accent, .06)!, AppColors.cave],
      ),
      shape: PixelBorder(
        step: 7,
        side: BorderSide(color: accent, width: emphasized ? 3.5 : 1.8),
      ),
      shadows: [
        if (glow)
          BoxShadow(
            color: accent.withValues(alpha: emphasized ? .6 : .32),
            blurRadius: emphasized ? 23 : 12,
          ),
        const BoxShadow(
          color: Colors.black54,
          offset: Offset(0, 4),
          blurRadius: 3,
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      shape: const PixelBorder(step: 7),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            if (rail)
              Positioned(
                left: 0,
                top: 3,
                bottom: 3,
                width: 4,
                child: ColoredBox(color: accent),
              ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    ),
  );
}
