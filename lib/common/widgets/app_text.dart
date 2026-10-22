import 'package:flutter/material.dart';

import '../../core/localization/app_translations.dart';
import '../../core/theme/app_text_styles.dart';
export '../../core/localization/app_translations.dart' show TranslateContext;

/// Translates app-owned text. Unknown values (names, seeds, addresses) stay intact.
class AppText extends StatelessWidget {
  const AppText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    this.semanticsLabel,
  });
  final String data;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) => Text(
    context.tr(data),
    style: style?.copyWith(fontFamilyFallback: AppFonts.fallback),
    textAlign: textAlign,
    maxLines: maxLines,
    overflow: overflow,
    softWrap: softWrap,
    semanticsLabel: semanticsLabel == null ? null : context.tr(semanticsLabel!),
  );
}
