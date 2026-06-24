import 'package:flutter/material.dart';
import '../models/order.dart';
import '../utils/currency_formatter.dart';
import 'status_chip.dart';

/// 订单列表卡片组件
class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;

  const OrderCard({super.key, required this.order, this.onTap});

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
            ],
          ),
        ),
      ),
    );
  }
}
