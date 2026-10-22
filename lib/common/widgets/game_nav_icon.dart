import 'package:flutter/material.dart';

import '../../core/navigation/app_destination.dart';
import '../../core/responsive/app_layout.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/character_palette.dart';
import 'voxel_character.dart';

class GameNavIcon extends StatelessWidget {
  const GameNavIcon({super.key, required this.destination});
  final AppDestination destination;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: AppLayout.navigationIconSize,
    child: switch (destination) {
      AppDestination.skins => const VoxelCharacter(headOnly: true),
      AppDestination.history => const Icon(
        Icons.timer_outlined,
        size: AppLayout.navigationIconSize,
        color: AppColors.textSecondary,
      ),
      _ => CustomPaint(painter: _NavPainter(destination)),
    },
  );
}

class _NavPainter extends CustomPainter {
  const _NavPainter(this.destination);
  final AppDestination destination;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 32, size.height / 32);
    void rect(double x, double y, double w, double h, Color color) =>
        canvas.drawRect(
          Rect.fromLTWH(x, y, w, h),
          Paint()
            ..color = color
            ..isAntiAlias = false,
        );
    if (destination == AppDestination.find) {
      for (var i = 0; i < 5; i++) {
        rect(12 + i * 3, 13 + i * 3, 5, 5, CharacterPalette.outline);
        rect(13 + i * 3, 14 + i * 3, 3, 3, CharacterPalette.explorer.shirt);
      }
      rect(4, 5, 20, 5, CharacterPalette.outline);
      rect(3, 9, 8, 15, CharacterPalette.outline);
      rect(5, 6, 18, 3, AppColors.action);
      rect(5, 9, 4, 13, AppColors.action);
      rect(9, 9, 10, 3, AppColors.action);
    } else if (destination == AppDestination.servers) {
      rect(2, 3, 28, 21, CharacterPalette.outline);
      rect(4, 5, 24, 17, AppColors.banner);
      rect(14, 24, 4, 4, AppColors.chipSurface);
      rect(9, 28, 14, 2, AppColors.border);
    } else {
      canvas.drawCircle(
        const Offset(16, 16),
        15,
        Paint()..color = CharacterPalette.outline,
      );
      canvas.save();
      canvas.clipPath(Path()..addOval(const Rect.fromLTWH(2, 2, 28, 28)));
      rect(0, 0, 32, 32, AppColors.action);
      rect(4, 4, 9, 6, CharacterPalette.explorer.trousers);
      rect(9, 9, 12, 5, CharacterPalette.explorer.trousers);
      rect(18, 14, 9, 7, CharacterPalette.explorer.shirt);
      rect(8, 20, 8, 9, CharacterPalette.explorer.trousers);
      rect(23, 3, 7, 5, CharacterPalette.explorer.shirt);
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_NavPainter oldDelegate) =>
      destination != oldDelegate.destination;
}
