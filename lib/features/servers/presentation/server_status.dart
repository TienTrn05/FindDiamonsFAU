import 'package:flutter/material.dart';
import '../../../common/widgets/app_text.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/server_catalog.dart';

class ServerStatus extends StatelessWidget {
  const ServerStatus({super.key, required this.server, this.compact = true});
  final ServerItem server;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final color = switch (server.availability) {
      true => AppColors.online,
      false => AppColors.danger,
      null => AppColors.textMuted,
    };
    final label = switch (server.availability) {
      true => 'Online',
      false => 'Offline',
      null => 'Unknown',
    };
    final current = server.currentPlayers;
    final maximum = server.maximumPlayers;
    final count = current == null
        ? '\u2014'
        : maximum == null
        ? '$current'
        : '$current/$maximum';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AppText(
          count,
          key: ValueKey('server-count-${server.id}'),
          style: AppTextStyles.body.copyWith(
            fontSize: compact ? 11 : 16,
            color: AppColors.onPrimary,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: .25), blurRadius: 4),
                ],
              ),
            ),
            const SizedBox(width: 4),
            AppText(
              label,
              key: ValueKey('server-status-${server.id}'),
              style: AppTextStyles.body.copyWith(
                fontSize: compact ? 9 : 12,
                color: AppColors.caveMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
