import 'package:flutter/material.dart';
import '../models/order.dart';
import '../utils/currency_formatter.dart';
import 'status_chip.dart';

/// 订单列表卡片组件
class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onUncomplete;

  const OrderCard({
    super.key,
    required this.order,
    this.onTap,
    this.onComplete,
    this.onUncomplete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 第一行：订单编号 + 状态
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#${order.orderNo}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(179),
                      fontFamily: 'monospace',
                    ),
                  ),
                  StatusChip(status: order.status),
                ],
              ),
              const SizedBox(height: 8),

              // 第二行：客户名 + 类型
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.customerName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (order.manager.isNotEmpty)
                    Text(
                      order.manager,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(153),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // 第三行：金额 + 截止日期
              Row(
                children: [
                  Text(
                    '${CurrencyFormatter.formatCompact(order.totalAmount)} / 已收${CurrencyFormatter.formatCompact(order.paidAmount)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(179),
                    ),
                  ),
                  const Spacer(),
                  if (order.deadline != null)
                    Text(
                      '截止: ${order.deadline!.month}/${order.deadline!.day}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: order.deadline!.isBefore(DateTime.now())
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurface.withAlpha(153),
                      ),
                    ),
                ],
              ),
              // 标记完成按钮（待处理/进行中 状态显示）
              if (onComplete != null &&
                  order.status != '已完成' &&
                  order.status != '已结算' &&
                  order.status != '已取消') ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onComplete,
                    icon: const Icon(Icons.check_circle, size: 20),
                    label: const Text('标记完成'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
              // 恢复待处理按钮（已完成 状态显示，防返工）
              if (onUncomplete != null &&
                  order.status == '已完成') ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onUncomplete,
                    icon: const Icon(Icons.undo, size: 20),
                    label: const Text('恢复待处理'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
