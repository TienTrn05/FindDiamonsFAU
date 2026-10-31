import 'app_text.dart';
import 'package:flutter/material.dart';
import '../../core/formatters/signed_integer_input_formatter.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/theme/app_theme.dart';

class GameTextField extends StatelessWidget {
  const GameTextField({
    super.key,
    required this.label,
    required this.controller,
    this.numeric = false,
    this.validator,
    this.readOnly = false,
    this.hintText,
    this.labelStyle,
    this.valueStyle,
    this.decoration,
    this.icon,
    this.labelSpacing = AppSpacing.xs,
    this.iconColor,
  });
  final String label;
  final TextEditingController controller;
  final bool numeric;
  final String? Function(String?)? validator;
  final bool readOnly;
  final String? hintText;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;
  final InputDecoration? decoration;
  final IconData? icon;
  final double labelSpacing;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: iconColor ?? labelStyle?.color),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: AppText(
              label,
              style: labelStyle ?? AppTextStyles.fieldLabel,
            ),
          ),
        ],
      ),
      SizedBox(height: labelSpacing),
      TextFormField(
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        controller: controller,
        readOnly: readOnly,
        autocorrect: !numeric,
        enableSuggestions: !numeric,
        inputFormatters: numeric ? const [SignedIntegerInputFormatter()] : null,
        style: valueStyle ?? AppTextStyles.fieldValue,
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(signed: true)
            : TextInputType.text,
        textInputAction: TextInputAction.next,
        validator: (value) {
          final error = validator?.call(value);
          return error == null ? null : context.tr(error);
        },
        decoration: (decoration ?? AppTheme.gameInputDecoration).copyWith(
          hintText: hintText == null ? null : context.tr(hintText!),
        ),
      ),
    ],
  );
}
