import 'package:flutter/material.dart';
import '../config/app_constants.dart';

/// 状态变更底部弹窗
class StatusBottomSheet extends StatelessWidget {
  final String currentStatus;
  final ValueChanged<String> onSelected;

  const StatusBottomSheet({
    super.key,
    required this.currentStatus,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withAlpha(51),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '更改订单状态',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...OrderStatus.all.map((status) {
              final isCurrent = status == currentStatus;
              final color = Color(OrderStatus.colors[status] ?? 0xFF757575);

              return ListTile(
                leading: Icon(
                  isCurrent ? Icons.radio_button_checked : Icons.radio_button_off,
                  color: color,
                ),
                title: Text(
                  status,
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCurrent
                        ? color
                        : theme.colorScheme.onSurface,
                  ),
                ),
                trailing: isCurrent
                    ? Text(
                        '当前',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withAlpha(102),
                        ),
                      )
                    : null,
                onTap: () {
                  if (!isCurrent) {
                    onSelected(status);
                  }
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  /// 弹出底部弹窗
  static void show(
    BuildContext context, {
    required String currentStatus,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      builder: (_) => StatusBottomSheet(
        currentStatus: currentStatus,
        onSelected: onSelected,
      ),
    );
  }
}
