import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class LandscapeBackground extends StatelessWidget {
  const LandscapeBackground({
    super.key,
    required this.child,
    this.washed = false,
  });
  final Widget child;
  final bool washed;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset('assets/images/block_landscape.png', fit: BoxFit.cover),
      if (washed) const ColoredBox(color: AppColors.landscapeWash),
      child,
    ],
  );
}
