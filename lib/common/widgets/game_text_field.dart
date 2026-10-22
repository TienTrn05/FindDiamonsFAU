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
  });
  final String label;
  final TextEditingController controller;
  final bool numeric;
  final String? Function(String?)? validator;
  final bool readOnly;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      AppText(label, style: AppTextStyles.fieldLabel),
      const SizedBox(height: AppSpacing.xs),
      TextFormField(
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
        controller: controller,
        readOnly: readOnly,
        autocorrect: !numeric,
        enableSuggestions: !numeric,
        inputFormatters: numeric ? const [SignedIntegerInputFormatter()] : null,
        style: AppTextStyles.fieldValue,
        keyboardType: numeric
            ? const TextInputType.numberWithOptions(signed: true)
            : TextInputType.text,
        textInputAction: TextInputAction.next,
        validator: (value) {
          final error = validator?.call(value);
          return error == null ? null : context.tr(error);
        },
        decoration: AppTheme.gameInputDecoration,
      ),
    ],
  );
}
