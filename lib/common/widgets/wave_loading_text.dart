import 'dart:math' as math;
import 'package:flutter/material.dart';

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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.text.length, (index) {
            final phase = _controller.value * 2 * math.pi - index * 0.45;

            final wave = math.pow(math.max(0.0, math.sin(phase)), 2).toDouble();

            return Transform.translate(
              offset: Offset(0, -8 * wave),
              child: Opacity(
                opacity: 0.6 + 0.4 * wave,
                child: Text(widget.text[index], style: widget.style),
              ),
            );
          }),
        );
      },
    );
  }
}
