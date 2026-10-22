import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Centers short content and lets it scroll on short screens or with large text.
class AppCenteredScrollView extends StatelessWidget {
  const AppCenteredScrollView({
    super.key,
    required this.child,
    this.padding = AppInsets.screen,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(padding: padding, child: child),
  );
}
