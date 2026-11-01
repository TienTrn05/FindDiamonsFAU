import 'package:flutter/material.dart';
import 'mining_surface.dart';

class LandscapeBackground extends StatelessWidget {
  const LandscapeBackground({
    super.key,
    required this.child,
    this.washed = false,
  });
  final Widget child;
  final bool washed;

  @override
  Widget build(BuildContext context) => MiningBackground(child: child);
}
