import 'package:flutter/material.dart';
import '../../../common/widgets/mining_surface.dart';

import '../../../common/widgets/app_text.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/server_catalog.dart';

class ServerConnectionDialog extends StatefulWidget {
  const ServerConnectionDialog({
    super.key,
    required this.server,
    required this.onCopy,
  });

  final ServerItem server;
  final Future<void> Function() onCopy;

  @override
  State<ServerConnectionDialog> createState() => _ServerConnectionDialogState();
}

class _ServerConnectionDialogState extends State<ServerConnectionDialog> {
  bool _copied = false;

  Future<void> _copy() async {
    await widget.onCopy();
    if (mounted) setState(() => _copied = true);
  }

  @override
  Widget build(BuildContext context) => Dialog(
    key: const ValueKey('server-connection-dialog'),
    backgroundColor: AppColors.surface,
    surfaceTintColor: AppColors.transparent,
    insetPadding: const EdgeInsets.all(AppSpacing.lg),
    shape: const PixelBorder(
      side: BorderSide(color: AppColors.helpBorder, width: 2),
    ),
    clipBehavior: Clip.antiAlias,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: DefaultTextStyle(
          style: AppTextStyles.body.copyWith(
            color: AppColors.text,
            fontFamilyFallback: AppFonts.fallback,
            fontSize: 13,
            height: 1.45,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AppText('1. Open the Minecraft app'),
              const AppText(
                '2. Tap "Play", then "Servers", and scroll to the bottom',
              ),
              const AppText(
                '3. Tap "Add Server", then enter the details below:',
              ),
              const SizedBox(height: AppSpacing.sm),
              Table(
                columnWidths: const {
                  0: FractionColumnWidth(.34),
                  1: FlexColumnWidth(),
                },
                defaultVerticalAlignment: TableCellVerticalAlignment.top,
                children: [
                  _row('Server Name:', AppText(widget.server.name)),
                  _row(
                    'Server Address:',
                    Material(
                      color: AppColors.transparent,
                      child: InkWell(
                        key: const ValueKey('server-dialog-copy-address'),
                        onTap: _copy,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xs,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(widget.server.address),
                              AppText(
                                _copied ? 'COPIED!' : '(Tap to Copy)',
                                style: AppTextStyles.body.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  _row('Port:', AppText('${widget.server.port}')),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              TextButton(
                key: const ValueKey('close-server-connection'),
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.oreRow,
                  foregroundColor: AppColors.text,
                  minimumSize: const Size.fromHeight(52),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadii.standard,
                  ),
                ),
                child: const AppText('Close', style: AppTextStyles.pixelButton),
              ),
            ],
          ),
        ),
      ),
    ),
  );

  TableRow _row(String label, Widget value) => TableRow(
    children: [
      Padding(
        padding: const EdgeInsets.only(
          top: AppSpacing.sm,
          right: AppSpacing.sm,
        ),
        child: AppText(label),
      ),
      Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: value,
      ),
    ],
  );
}
