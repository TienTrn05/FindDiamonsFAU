import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/localization/app_translations.dart';
import '../../core/theme/app_text_styles.dart';

class WaveLoadingText extends StatefulWidget {
  final String text;
  final TextStyle? style;

  const WaveLoadingText({super.key, this.text = 'Please wait...', this.style});

  @override
  State<WaveLoadingText> createState() => _WaveLoadingTextState();
}

class _WaveLoadingTextState extends State<WaveLoadingText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = context.tr(widget.text);
    return Semantics(
      label: text,
      child: ExcludeSemantics(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(text.length, (index) {
                  final phase = _controller.value * 2 * math.pi - index * 0.45;

                  final wave = math
                      .pow(math.max(0.0, math.sin(phase)), 2)
                      .toDouble();

                  return Transform.translate(
                    offset: Offset(0, -8 * wave),
                    child: Opacity(
                      opacity: 0.6 + 0.4 * wave,
                      child: Text(
                        text[index],
                        style: widget.style?.copyWith(
                          fontFamilyFallback: AppFonts.fallback,
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
      ),
    );
  }
}
