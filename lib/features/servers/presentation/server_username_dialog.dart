import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';

class ServerUsernameDialog extends StatefulWidget {
  const ServerUsernameDialog({super.key, this.username});

  final String? username;

  @override
  State<ServerUsernameDialog> createState() => _ServerUsernameDialogState();
}

class _ServerUsernameDialogState extends State<ServerUsernameDialog> {
  late final _controller = TextEditingController(text: widget.username ?? '');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    key: const ValueKey('server-username-dialog'),
    backgroundColor: AppColors.surface,
    surfaceTintColor: AppColors.transparent,
    elevation: 0,
    constraints: const BoxConstraints(maxWidth: 232),
    insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(11),
      side: const BorderSide(color: AppColors.action, width: 6),
    ),
    clipBehavior: Clip.antiAlias,
    child: SizedBox(
      width: 232,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'Enter your Minecraft username',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  color: AppColors.text,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              key: const ValueKey('server-username-input'),
              controller: _controller,
              autofocus: true,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              textInputAction: TextInputAction.done,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9_]')),
                LengthLimitingTextInputFormatter(16),
              ],
              style: const TextStyle(
                fontFamily: 'Monocraft',
                fontSize: 22,
                color: AppColors.text,
              ),
              cursorColor: const Color(0xFF3E75DD),
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 18,
                ),
                enabledBorder: _inputBorder,
                focusedBorder: _inputBorder,
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  flex: 6,
                  child: TextButton(
                    key: const ValueKey('server-username-cancel'),
                    onPressed: () => Navigator.pop(context),
                    style: _buttonStyle(AppColors.oreRow, AppColors.text),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 5,
                  child: TextButton(
                    key: const ValueKey('server-username-save'),
                    onPressed: () =>
                        Navigator.pop(context, _controller.text.trim()),
                    style: _buttonStyle(AppColors.danger, AppColors.onPrimary),
                    child: const Text('OK'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  OutlineInputBorder get _inputBorder => OutlineInputBorder(
    borderRadius: BorderRadius.circular(4),
    borderSide: const BorderSide(color: AppColors.action, width: 3),
  );

  ButtonStyle _buttonStyle(Color background, Color foreground) =>
      TextButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 52),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontFamily: 'Monocraft', fontSize: 22),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      );
}
