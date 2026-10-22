import '../../../common/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/help_content.dart';
import 'help_action_button.dart';

class HelpPolicyDialog extends StatefulWidget {
  const HelpPolicyDialog({super.key, required this.sections});
  final List<HelpPolicySection> sections;

  @override
  State<HelpPolicyDialog> createState() => _HelpPolicyDialogState();
}

class _HelpPolicyDialogState extends State<HelpPolicyDialog> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _link(HelpPolicySection section) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: AppText(section.title),
      content: SelectableText(section.url),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const AppText('Close'),
        ),
        TextButton(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: section.url));
            if (context.mounted) Navigator.pop(context);
          },
          child: const AppText('Copy link'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: AppColors.surface,
    surfaceTintColor: AppColors.surface,
    insetPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.xl,
      vertical: AppSpacing.xxl,
    ),
    shape: const RoundedRectangleBorder(borderRadius: AppRadii.standard),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 480,
        maxHeight: MediaQuery.sizeOf(context).height * .86,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Scrollbar(
                controller: _scroll,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  key: const ValueKey('help-policy-scroll'),
                  controller: _scroll,
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final section in widget.sections) ...[
                        AppText(
                          section.title,
                          style: AppTextStyles.helpHeading,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppText(section.body, style: AppTextStyles.helpBody),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            alignment: Alignment.centerLeft,
                          ),
                          onPressed: () => _link(section),
                          child: AppText(
                            section.linkLabel,
                            style: AppTextStyles.helpLink,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const Divider(),
            const SizedBox(height: AppSpacing.sm),
            HelpActionButton(
              key: const ValueKey('help-policy-ok'),
              label: 'OK',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    ),
  );
}
