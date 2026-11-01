import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_text.dart';
import 'mining_surface.dart';

class MiningTag extends StatelessWidget {
  const MiningTag(
    this.label, {
    super.key,
    this.icon,
    this.color = AppColors.primary,
  });
  final String label;
  final IconData? icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: color.withValues(alpha: .35)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
        ],
        Flexible(
          child: AppText(
            label,
            style: AppTextStyles.body.copyWith(fontSize: 11, color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

class MiningEmptyState extends StatelessWidget {
  const MiningEmptyState({
    super.key,
    required this.title,
    required this.icon,
    this.message,
    this.action,
    this.onAction,
  });
  final String title;
  final IconData icon;
  final String? message;
  final String? action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: .18),
                  AppColors.transparent,
                ],
              ),
            ),
            child: Icon(icon, size: 52, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          AppText(
            title,
            style: AppTextStyles.itemTitle.copyWith(color: AppColors.text),
            textAlign: TextAlign.center,
          ),
          if (message != null) ...[
            const SizedBox(height: 10),
            AppText(
              message!,
              style: AppTextStyles.body.copyWith(color: AppColors.caveMuted),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[
            const SizedBox(height: 24),
            MiningButton(
              label: action!,
              onPressed: onAction,
              trailing: Icons.arrow_forward,
            ),
          ],
        ],
      ),
    ),
  );
}

class MiningStage extends StatelessWidget {
  const MiningStage({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: RadialGradient(
        center: const Alignment(0, .4),
        radius: 1,
        colors: [AppColors.cavePanel, AppColors.cave],
      ),
    ),
    child: CustomPaint(painter: const _StageGrid(), child: child),
  );
}

class _StageGrid extends CustomPainter {
  const _StageGrid();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withValues(alpha: .09)
      ..strokeWidth = 1;
    final horizon = size.height * .62;
    for (var x = -size.width; x <= size.width * 2; x += 28) {
      canvas.drawLine(
        Offset(size.width / 2 + (x - size.width / 2) * .15, horizon),
        Offset(x, size.height),
        paint,
      );
    }
    for (var y = horizon; y < size.height; y += 16) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_StageGrid oldDelegate) => false;
}
