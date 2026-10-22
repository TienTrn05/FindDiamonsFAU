import 'package:flutter/material.dart';

import '../../core/responsive/app_layout.dart';

/// Fits reference artwork inside the available constraints. Ordinary page text
/// should use normal Flutter layout so it can wrap and follow text scaling.
class ResponsiveCanvas extends StatelessWidget {
  const ResponsiveCanvas({
    super.key,
    this.designSize = AppLayout.referenceCanvasSize,
    required this.child,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  });

  final Size designSize;
  final Widget child;
  final BoxFit fit;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: fit,
    alignment: alignment,
    child: SizedBox.fromSize(size: designSize, child: child),
  );
}
