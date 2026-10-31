import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Uses the actual space left by safe areas, navigation, keyboard and SDK ads.
/// Short viewports fit the complete composition without introducing a scroll area.
class MiningViewport extends StatelessWidget {
  const MiningViewport({
    super.key,
    required this.minimumHeight,
    required this.compactHeight,
    required this.builder,
  });
  final double minimumHeight;
  final double compactHeight;
  final Widget Function(BuildContext, bool landscape, bool compact) builder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final landscape = constraints.maxWidth > constraints.maxHeight * 1.15;
      final compact = constraints.maxHeight < 520;
      final textScale = MediaQuery.textScalerOf(context).scale(1);
      final height =
          (landscape
              ? 360.0
              : compact
              ? compactHeight
              : minimumHeight) *
          math.max(1, textScale);
      final scale = math.min(1.0, constraints.maxHeight / height);
      if (scale <= 0) return const SizedBox.shrink();
      return FittedBox(
        fit: BoxFit.contain,
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: constraints.maxWidth / scale,
          height: constraints.maxHeight / scale,
          child: builder(context, landscape, compact),
        ),
      );
    },
  );
}
