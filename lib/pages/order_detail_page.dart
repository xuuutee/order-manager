import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
import '../providers/order_type_provider.dart';
import '../utils/currency_formatter.dart';
import '../widgets/status_chip.dart';
import '../widgets/status_bottom_sheet.dart';
import 'order_form_page.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderId;

  const OrderDetailPage({super.key, required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Order? _order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    final provider = context.read<OrderProvider>();
    // 先从当前列表查找
    final order =
        provider.orders.where((o) => o.id == widget.orderId).firstOrNull;

    if (order != null) {
      setState(() {
        _order = order;
        _isLoading = false;
      });
    } else {
      // 列表中找不到则单独查询（不再加载全部订单）
      final fetched = await provider.fetchOrderById(widget.orderId);
      if (mounted) {
        setState(() {
          _order = fetched;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeProvider = context.watch<OrderTypeProvider>();

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('订单详情')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('订单详情')),
        body: const Center(child: Text('订单不存在或已删除')),
      );
    }

    final order = _order!;
    final typeName = typeProvider.getTypeNameById(order.orderTypeId);

    return Scaffold(
      appBar: AppBar(
        title: Text('#${order.orderNo}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OrderFormPage(order: order),
                ),
              );
              // 返回后刷新
              _loadOrder();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (action) async {
              if (action == 'delete') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('删除订单'),
                    content: Text('确定要删除订单 #${order.orderNo} 吗？此操作不可撤销。'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('取消'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                        child: const Text('删除'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  final success = await context
                      .read<OrderProvider>()
                      .deleteOrder(order.id);
                  if (mounted) {
                    if (success) {
                      Navigator.of(context).pop(); // 返回列表
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('删除失败')),
                      );
                    }
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('删除订单', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ===== 状态卡片 =====
          Card(
            child: InkWell(
              onTap: () {
                StatusBottomSheet.show(
                  context,
                  currentStatus: order.status,
                  onSelected: (newStatus) async {
                    Navigator.of(context).pop(); // 关闭弹窗
                    final success = await context
                        .read<OrderProvider>()
                        .updateStatus(order.id, newStatus);
                    if (success) {
                      _loadOrder();
                    }
                  },
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '订单状态',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(153),
                          ),
                        ),
                        const SizedBox(height: 6),
                        StatusChip(status: order.status),
                      ],
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurface.withAlpha(102),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ===== 基本信息卡片 =====
          _buildInfoCard(
            theme: theme,
            title: '基本信息',
            items: [
              _infoItem('客户昵称', order.customerName),
              _infoItem('联系方式', order.contact.isEmpty ? '-' : order.contact),
              _infoItem('订单类型', typeName),
              _infoItem('负责人', order.manager.isEmpty ? '-' : order.manager),
            ],
          ),

          const SizedBox(height: 12),

          // ===== 金额信息卡片 =====
          _buildInfoCard(
            theme: theme,
            title: '金额信息',
            items: [
              _infoItem('订单金额', CurrencyFormatter.format(order.totalAmount)),
              _infoItem('已收金额', CurrencyFormatter.format(order.paidAmount)),
              _infoItem(
                '未收金额',
                CurrencyFormatter.format(order.unpaidAmount),
                valueColor: order.unpaidAmount > 0
                    ? theme.colorScheme.error
                    : theme.colorScheme.primary,
              ),
            ],
            trailing: TextButton.icon(
              onPressed: () => _editPaidAmount(order),
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('修改已收金额'),
            ),
          ),

          const SizedBox(height: 12),

          // ===== 时间信息卡片 =====
          _buildInfoCard(
            theme: theme,
            title: '时间信息',
            items: [
              _infoItem(
                '开始时间',
                order.startDate != null
                    ? '${order.startDate!.year}-${order.startDate!.month.toString().padLeft(2, '0')}-${order.startDate!.day.toString().padLeft(2, '0')}'
                    : '-',
              ),
              _infoItem(
                '截止时间',
                order.deadline != null
                    ? '${order.deadline!.year}-${order.deadline!.month.toString().padLeft(2, '0')}-${order.deadline!.day.toString().padLeft(2, '0')}'
                    : '-',
              ),
              _infoItem(
                '创建时间',
                '${order.createdAt.year}-${order.createdAt.month.toString().padLeft(2, '0')}-${order.createdAt.day.toString().padLeft(2, '0')} '
                    '${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}',
              ),
              _infoItem(
                '更新时间',
                '${order.updatedAt.year}-${order.updatedAt.month.toString().padLeft(2, '0')}-${order.updatedAt.day.toString().padLeft(2, '0')} '
                    '${order.updatedAt.hour.toString().padLeft(2, '0')}:${order.updatedAt.minute.toString().padLeft(2, '0')}',
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ===== 备注卡片 =====
          _buildInfoCard(
            theme: theme,
            title: '备注',
            items: [
              _infoItem(
                '',
                order.remark.isEmpty ? '无备注' : order.remark,
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ========== 快捷收款弹窗 ==========
  Future<void> _editPaidAmount(Order order) async {
    final controller =
        TextEditingController(text: order.paidAmount.toString());
    final formKey = GlobalKey<FormState>();

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('修改已收金额 — #${order.orderNo}'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '订单金额：${CurrencyFormatter.format(order.totalAmount)}',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: '已收金额',
                  prefixText: '¥ ',
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return '请输入金额';
                  final val = double.tryParse(v);
                  if (val == null) return '请输入有效金额';
                  if (val < 0) return '金额不能为负';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final val = double.tryParse(controller.text) ?? 0;
                Navigator.pop(ctx, val);
              }
            },
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      final success = await context
          .read<OrderProvider>()
          .updatePaidAmount(order.id, result);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('已收金额已更新'),
              behavior: SnackBarBehavior.floating,
            ),
          );
          _loadOrder();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('更新失败'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  // ========== 信息卡片组件 ==========
  Widget _buildInfoCard({
    required ThemeData theme,
    required String title,
    required List<Widget> items,
    Widget? trailing,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
            const SizedBox(height: 12),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _infoItem(String label, String value, {Color? valueColor}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            SizedBox(
              width: 80,
              child: Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(153),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: valueColor ?? theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
