import 'package:flutter/material.dart';

import '../../../common/widgets/reward_unlock_dialog.dart';
import '../../../core/monetization/app_monetization.dart';
import '../../../core/theme/app_colors.dart';
import '../bloc/maps_bloc.dart';
import '../models/map_catalog.dart';

class MapUnlockDialog extends StatelessWidget {
  const MapUnlockDialog({
    super.key,
    required this.item,
    required this.bloc,
    required this.monetization,
  });

  final MapItem item;
  final MapsBloc bloc;
  final AppMonetization monetization;

  @override
  Widget build(BuildContext context) => RewardUnlockDialog(
    keyPrefix: 'map',
    title: 'Watch Ads to Unlock World',
    monetization: monetization,
    isLocked: () => bloc.isLocked(item, isPro: false),
    onUnlock: () => bloc.unlock(item.id),
    watchToUnlockMessage: 'Watch the ad to unlock this world.',
    saveFailureMessage:
        'World unlocked for this session. Unable to save it on this device.',
    illustration: UnlockCardIllustration(
      left: Image.asset('assets/images/adventurer.png', fit: BoxFit.cover),
      right: Image.asset('assets/images/warehouse.png', fit: BoxFit.cover),
      center: ColoredBox(
        color: AppColors.worldSky,
        child: Center(
          child: FractionallySizedBox(
            widthFactor: .6,
            child: AspectRatio(
              aspectRatio: 1,
              child: CustomPaint(painter: _GrassBlockPainter()),
            ),
          ),
        ),
      ),
    ),
  );
}

class _GrassBlockPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    void face(List<Offset> points, Color color) => canvas.drawPath(
      Path()..addPolygon(points, true),
      Paint()..color = color,
    );
    face([
      Offset(0, h * .24),
      Offset(w * .5, h * .1),
      Offset(w, h * .24),
      Offset(w * .5, h * .43),
    ], AppColors.worldGrass);
    face([
      Offset(0, h * .24),
      Offset(w * .5, h * .43),
      Offset(w * .5, h),
      Offset(0, h * .77),
    ], AppColors.worldEarth);
    face([
      Offset(w * .5, h * .43),
      Offset(w, h * .24),
      Offset(w, h * .77),
      Offset(w * .5, h),
    ], AppColors.worldEarthShade);
    face([
      Offset(0, h * .24),
      Offset(w * .5, h * .43),
      Offset(w * .5, h * .57),
      Offset(0, h * .38),
    ], AppColors.worldGrassLight);
    face([
      Offset(w * .5, h * .43),
      Offset(w, h * .24),
      Offset(w, h * .38),
      Offset(w * .5, h * .57),
    ], AppColors.worldGrass);
    for (final cell in [
      const Offset(.12, .56),
      const Offset(.29, .69),
      const Offset(.66, .65),
      const Offset(.8, .52),
    ]) {
      canvas.drawRect(
        Rect.fromLTWH(w * cell.dx, h * cell.dy, w * .09, h * .07),
        Paint()..color = AppColors.worldEarthShade,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GrassBlockPainter oldDelegate) => false;
}
