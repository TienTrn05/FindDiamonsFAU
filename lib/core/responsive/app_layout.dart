import 'package:flutter/widgets.dart';

/// Shared layout policy. Artwork can override the default reference size.
abstract final class AppLayout {
  static const maxContentWidth = 520.0;
  static const referenceCanvasSize = Size(374, 616);
  static const buttonMinHeight = 48.0;
  static const permissionButtonMinHeight = 42.0;
  static const navigationExtent = 56.0;
  static const progressIndicatorSize = 20.0;
  static const gameHeaderHeight = 100.0;
  static const navigationIconSize = 32.0;
  static const navigationMinHeight = 72.0;
  static const adBannerHeight = 60.0;
  static const fieldMinHeight = 48.0;
  static const compactContentWidth = 360.0;

  static bool compact(double width) => width < compactContentWidth;
  static int gridColumns(double width) => width >= 460 ? 3 : 2;
}
