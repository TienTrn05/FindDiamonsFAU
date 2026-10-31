import 'package:flutter/material.dart';

import '../../core/navigation/app_destination.dart';
import '../../core/responsive/app_layout.dart';
import '../../core/theme/app_colors.dart';

class GameNavIcon extends StatelessWidget {
  const GameNavIcon({
    super.key,
    required this.destination,
    this.selected = false,
  });
  final AppDestination destination;
  final bool selected;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: AppLayout.navigationIconSize,
    child: Icon(
      switch (destination) {
        AppDestination.dashboard => Icons.home_filled,
        AppDestination.find => Icons.hardware,
        AppDestination.history => Icons.menu_book,
        AppDestination.skins => Icons.face,
        AppDestination.servers => Icons.dns,
        AppDestination.maps => Icons.map_outlined,
      },
      size: AppLayout.navigationIconSize,
      color: selected ? AppColors.primary : AppColors.caveMuted,
    ),
  );
}
