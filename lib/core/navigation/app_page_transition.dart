import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// One motion language for tab changes and Material routes on every platform.
class AppPageTransition extends StatelessWidget {
  const AppPageTransition({
    super.key,
    required this.animation,
    required this.child,
    this.direction = 1,
    this.outgoing = false,
    this.secondaryAnimation,
  });
  static const duration = Duration(milliseconds: 380);
  static const curve = Cubic(.2, .8, .2, 1);
  final Animation<double> animation;
  final Widget child;
  final double direction;
  final bool outgoing;
  final Animation<double>? secondaryAnimation;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final curved = animation.drive(
      CurveTween(
        curve: outgoing ? curve : const Interval(.22, 1, curve: curve),
      ),
    );
    final opacity = outgoing
        ? animation
              .drive(
                CurveTween(
                  curve: const Interval(0, .28, curve: Curves.easeInOutCubic),
                ),
              )
              .drive(Tween(begin: 1.0, end: 0.0))
        : animation.drive(
            CurveTween(
              curve: const Interval(.28, 1, curve: Curves.easeOutCubic),
            ),
          );
    Widget result = FadeTransition(
      opacity: opacity,
      child: SlideTransition(
        position: curved.drive(
          Tween(
            begin: outgoing ? Offset.zero : Offset(direction * .16, 0),
            end: outgoing ? Offset(-direction * .08, 0) : Offset.zero,
          ),
        ),
        child: _TransitionSnapshot(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        ),
      ),
    );
    if (secondaryAnimation != null) {
      final covered = secondaryAnimation!.drive(CurveTween(curve: curve));
      result = FadeTransition(
        opacity: secondaryAnimation!
            .drive(
              CurveTween(
                curve: const Interval(0, .28, curve: Curves.easeInOutCubic),
              ),
            )
            .drive(Tween(begin: 1.0, end: 0.0)),
        child: SlideTransition(
          position: covered.drive(
            Tween(begin: Offset.zero, end: const Offset(-.08, 0)),
          ),
          child: result,
        ),
      );
    }
    return result;
  }
}

/// Rasterize a complex scene once for the brief slide, then release the texture.
/// Platform views use the live subtree; web keeps normal painting as recommended
/// by SnapshotWidget. The real page and its form state always stay mounted.
class _TransitionSnapshot extends StatefulWidget {
  const _TransitionSnapshot({
    required this.animation,
    this.secondaryAnimation,
    required this.child,
  });
  final Animation<double> animation;
  final Animation<double>? secondaryAnimation;
  final Widget child;
  @override
  State<_TransitionSnapshot> createState() => _TransitionSnapshotState();
}

class _TransitionSnapshotState extends State<_TransitionSnapshot> {
  final _snapshot = SnapshotController();
  bool _disabled = false;
  @override
  void initState() {
    super.initState();
    widget.animation.addStatusListener(_synchronize);
    widget.secondaryAnimation?.addStatusListener(_synchronize);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _disabled = kIsWeb || MediaQuery.disableAnimationsOf(context);
    _synchronize(widget.animation.status);
  }

  @override
  void didUpdateWidget(covariant _TransitionSnapshot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      oldWidget.animation.removeStatusListener(_synchronize);
      widget.animation.addStatusListener(_synchronize);
    }
    if (oldWidget.secondaryAnimation != widget.secondaryAnimation) {
      oldWidget.secondaryAnimation?.removeStatusListener(_synchronize);
      widget.secondaryAnimation?.addStatusListener(_synchronize);
    }
    _synchronize(widget.animation.status);
  }

  void _synchronize(AnimationStatus _) {
    bool moving(Animation<double>? animation) =>
        animation?.status == AnimationStatus.forward ||
        animation?.status == AnimationStatus.reverse;
    _snapshot.allowSnapshotting =
        !_disabled &&
        (moving(widget.animation) || moving(widget.secondaryAnimation));
  }

  @override
  void dispose() {
    widget.animation.removeStatusListener(_synchronize);
    widget.secondaryAnimation?.removeStatusListener(_synchronize);
    _snapshot.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SnapshotWidget(
    controller: _snapshot,
    mode: SnapshotMode.permissive,
    autoresize: true,
    child: widget.child,
  );
}

/// Directional shared-axis motion, retaining every page's element and form state.
class AppTabTransition extends StatelessWidget {
  const AppTabTransition({
    super.key,
    required this.animation,
    required this.index,
    required this.previousIndex,
    required this.direction,
    required this.children,
    this.background,
  });
  final Animation<double> animation;
  final int index;
  final int previousIndex;
  final double direction;
  final List<Widget> children;
  final Widget? background;

  @override
  Widget build(BuildContext context) {
    // Keep each scene's widget and animation chains stable between frames.
    // The animation listener below only updates visibility and paint order.
    final scenes = [
      for (var i = 0; i < children.length; i++)
        ExcludeSemantics(
          excluding: i != index,
          child: AppPageTransition(
            animation: animation,
            direction: direction,
            outgoing: i != index,
            child: RepaintBoundary(child: children[i]),
          ),
        ),
    ];
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final moving =
            animation.value < 1 && !MediaQuery.disableAnimationsOf(context);
        // Keys retain page state as paint order changes. The incoming scene is
        // always on top, including when moving toward a lower tab index.
        final order = [
          for (var i = 0; i < children.length; i++)
            if (i != previousIndex && i != index) i,
          if (previousIndex != index) previousIndex,
          index,
        ];
        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (background != null) Positioned.fill(child: background!),
              for (final i in order)
                Offstage(
                  key: ValueKey('tab-stage-$i'),
                  offstage: i != index && (!moving || i != previousIndex),
                  child: IgnorePointer(
                    ignoring: i != index || moving,
                    child: scenes[i],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();
  @override
  Duration get transitionDuration => AppPageTransition.duration;
  @override
  Duration get reverseTransitionDuration => AppPageTransition.duration;
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => AppPageTransition(
    animation: animation,
    secondaryAnimation: secondaryAnimation,
    child: child,
  );
}
