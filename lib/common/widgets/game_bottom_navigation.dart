import 'app_text.dart';
import 'package:flutter/material.dart';
import '../../core/navigation/app_destination.dart';
import '../../core/responsive/app_layout.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import 'game_nav_icon.dart';

class GameBottomNavigation extends StatefulWidget {
  const GameBottomNavigation({
    super.key,
    required this.selected,
    required this.onSelected,
  });
  final AppDestination selected;
  final ValueChanged<AppDestination> onSelected;

  @override
  State<GameBottomNavigation> createState() => _GameBottomNavigationState();
}

class _GameBottomNavigationState extends State<GameBottomNavigation> {
  AppDestination? _pressed;

  void _highlight(AppDestination destination, bool highlighted) {
    if (!mounted) return;
    setState(() {
      if (highlighted) {
        _pressed = destination;
      } else if (_pressed == destination) {
        _pressed = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    child: SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: AppLayout.navigationMinHeight,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: AppDestination.values
              .map(
                (destination) => Expanded(
                  child: Semantics(
                    selected: widget.selected == destination,
                    button: true,
                    label: context.tr(destination.label),
                    child: InkWell(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      focusColor: Colors.transparent,
                      overlayColor: const WidgetStatePropertyAll(
                        Colors.transparent,
                      ),
                      key: ValueKey('nav-${destination.name}'),
                      onTap: () => widget.onSelected(destination),
                      onHighlightChanged: (highlighted) =>
                          _highlight(destination, highlighted),
                      borderRadius: AppRadii.pill,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                          horizontal: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: widget.selected == destination
                              ? AppColors.navigationSelected
                              : AppColors.transparent,
                          borderRadius: AppRadii.pill,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GameNavIcon(destination: destination),
                            const SizedBox(height: AppSpacing.xs),
                            SizedBox(
                              width: double.infinity,
                              child: Center(
                                child: AnimatedScale(
                                  scale: _pressed == destination ? 1.1 : 1,
                                  duration: const Duration(milliseconds: 120),
                                  curve: Curves.easeOutCubic,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: AppText(
                                      destination.label,
                                      style: AppTextStyles.navigationLabel
                                          .copyWith(
                                            color: _pressed == destination
                                                ? AppColors.onPrimary
                                                : widget.selected == destination
                                                ? AppColors.primary
                                                : AppColors.text,
                                            shadows: _pressed == destination
                                                ? [
                                                    Shadow(
                                                      color: AppColors.text
                                                          .withValues(
                                                            alpha: .55,
                                                          ),
                                                      blurRadius: 3,
                                                    ),
                                                  ]
                                                : const [],
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    ),
  );
}
