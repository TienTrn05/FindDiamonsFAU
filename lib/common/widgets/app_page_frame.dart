import 'package:flutter/material.dart';

import '../../core/responsive/app_layout.dart';

/// Centers app content on wider displays using one shared width limit.
class AppPageFrame extends StatelessWidget {
  const AppPageFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppLayout.maxContentWidth),
      child: child,
    ),
  );
}
