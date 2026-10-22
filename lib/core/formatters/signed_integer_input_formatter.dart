import 'package:flutter/services.dart';

/// Allows integer editing, including an empty field or a leading minus.
/// Rejects an invalid edit rather than turning a pasted decimal into another number.
class SignedIntegerInputFormatter extends TextInputFormatter {
  const SignedIntegerInputFormatter();
  static final _integer = RegExp(r'^-?[0-9]*$');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => _integer.hasMatch(newValue.text) ? newValue : oldValue;
}
