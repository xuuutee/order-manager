import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_constants.dart';
import '../models/order.dart';
import '../providers/order_provider.dart';
import '../providers/order_type_provider.dart';
import '../utils/order_no_generator.dart';

class OrderFormPage extends StatefulWidget {
  /// 编辑模式时传入已有订单
  final Order? order;

  const OrderFormPage({super.key, this.order});

  bool get isEditing => order != null;

  @override
  State<OrderFormPage> createState() => _OrderFormPageState();
}

class _OrderFormPageState extends State<OrderFormPage> {
  final _formKey = GlobalKey<FormState>();

  // 控制器
  late final TextEditingController _customerNameCtrl;
  late final TextEditingController _contactCtrl;
  late final TextEditingController _totalAmountCtrl;
  late final TextEditingController _paidAmountCtrl;
  late final TextEditingController _managerCtrl;
  late final TextEditingController _remarkCtrl;

  // 选择值
  String? _orderTypeId;
  String _status = OrderStatus.pending;
  DateTime? _startDate;
  DateTime? _deadline;
  bool _showMore = false;

  bool _isSaving = false;
  String? _generatedOrderNo;

  @override
  void initState() {
    super.initState();
    final o = widget.order;

    _customerNameCtrl = TextEditingController(text: o?.customerName ?? '');
    _contactCtrl = TextEditingController(text: o?.contact ?? '');
    _totalAmountCtrl =
        TextEditingController(text: o != null ? o.totalAmount.toString() : '');
    _paidAmountCtrl =
        TextEditingController(text: o != null ? o.paidAmount.toString() : '');
    _managerCtrl = TextEditingController(text: o?.manager ?? '');
    _remarkCtrl = TextEditingController(text: o?.remark ?? '');

    _orderTypeId = o?.orderTypeId;
    _status = o?.status ?? OrderStatus.pending;
    _startDate = o?.startDate ?? DateTime.now();
    _deadline = o?.deadline;
    _generatedOrderNo = o?.orderNo;
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _contactCtrl.dispose();
    _totalAmountCtrl.dispose();
    _paidAmountCtrl.dispose();
    _managerCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeProvider = context.watch<OrderTypeProvider>();
    final orderTypes = typeProvider.types;

    // 计算未收金额
    final total = double.tryParse(_totalAmountCtrl.text) ?? 0;
    final paid = double.tryParse(_paidAmountCtrl.text) ?? 0;
    final unpaid = total - paid;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? '编辑订单' : '发布订单'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ===== 订单编号（仅编辑时显示） =====
            if (widget.isEditing && _generatedOrderNo != null) ...[
              _readOnlyField('订单编号', _generatedOrderNo!, theme),
              const SizedBox(height: 16),
            ],

            // ===== 核心字段 =====
            TextFormField(
              controller: _customerNameCtrl,
              decoration: const InputDecoration(
                labelText: '客户昵称 *',
                hintText: '微信昵称或客户称呼',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? '请输入客户昵称' : null,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _totalAmountCtrl,
                    decoration: const InputDecoration(
                      labelText: '订单金额 *',
                      prefixText: '¥ ',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return '请输入订单金额';
                      if (double.tryParse(v) == null) return '请输入有效金额';
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _orderTypeId,
                    decoration: const InputDecoration(
                      labelText: '订单类型',
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('选择类型'),
                    isExpanded: true,
                    items: orderTypes.map((t) {
                      return DropdownMenuItem(
                        value: t.id,
                        child: Text(t.name, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _orderTypeId = v),
                  ),
                ),
              ],
            ),

            // ===== 未收金额（编辑时显示） =====
            if (widget.isEditing) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: unpaid > 0
                      ? theme.colorScheme.errorContainer.withAlpha(80)
                      : theme.colorScheme.primaryContainer.withAlpha(60),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text('未收金额：', style: theme.textTheme.bodyMedium),
                    Text(
                      '¥${unpaid.toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: unpaid > 0
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // ===== 更多信息 折叠入口 =====
            InkWell(
              onTap: () => setState(() => _showMore = !_showMore),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      _showMore ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                      color: theme.colorScheme.onSurface.withAlpha(153),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '更多信息',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(153),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '联系方式、负责人、金额明细、备注…',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(102),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (_showMore) ...[
              const SizedBox(height: 4),

              // 联系方式
              TextFormField(
                controller: _contactCtrl,
                decoration: const InputDecoration(
                  labelText: '联系方式',
                  hintText: '手机号 / 微信号 / QQ号',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),

              // 负责人
              TextFormField(
                controller: _managerCtrl,
                decoration: const InputDecoration(
                  labelText: '负责人',
                  hintText: '负责此订单的成员',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),

              // 已收金额
              TextFormField(
                controller: _paidAmountCtrl,
                decoration: const InputDecoration(
                  labelText: '已收金额',
                  prefixText: '¥ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),

              // 时间安排
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      label: '开始时间',
                      date: _startDate,
                      onPicked: (d) => setState(() => _startDate = d),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateField(
                      label: '截止时间',
                      date: _deadline,
                      onPicked: (d) => setState(() => _deadline = d),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 订单状态（始终在更多信息中显示）
              _sectionLabel('订单状态', theme),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: OrderStatus.all.map((s) {
                  final isSelected = _status == s;
                  return ChoiceChip(
                    label: Text(s),
                    selected: isSelected,
                    onSelected: (v) {
                      if (v) setState(() => _status = s);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // 备注
              TextFormField(
                controller: _remarkCtrl,
                decoration: const InputDecoration(
                  labelText: '备注',
                  hintText: '订单备注信息…',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                textInputAction: TextInputAction.newline,
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface.withAlpha(153),
      ),
    );
  }

  Widget _readOnlyField(String label, String value, ThemeData theme) {
    return TextFormField(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      readOnly: true,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontFamily: 'monospace',
        color: theme.colorScheme.onSurface.withAlpha(153),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required ValueChanged<DateTime> onPicked,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2035),
        );
        if (picked != null) onPicked(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today, size: 18),
        ),
        child: Text(
          date != null
              ? '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
              : '选择日期',
          style: TextStyle(
            fontSize: 14,
            color: date != null ? null : Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // 自动生成订单编号
    String orderNo;
    if (_generatedOrderNo != null) {
      orderNo = _generatedOrderNo!;
    } else {
      try {
        orderNo = await OrderNoGenerator.generate();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('生成订单编号失败，请重试')),
          );
        }
        return;
      }
    }

    final data = {
      'order_no': orderNo,
      'customer_name': _customerNameCtrl.text.trim(),
      'contact': _contactCtrl.text.trim(),
      'order_type_id': _orderTypeId,
      'total_amount': double.tryParse(_totalAmountCtrl.text) ?? 0,
      'paid_amount': double.tryParse(_paidAmountCtrl.text) ?? 0,
      'manager': _managerCtrl.text.trim(),
      'start_date': _startDate?.toIso8601String(),
      'deadline': _deadline?.toIso8601String(),
      'status': _status,
      'remark': _remarkCtrl.text.trim(),
    };

    setState(() => _isSaving = true);

    final provider = context.read<OrderProvider>();
    bool success;

    if (widget.isEditing) {
      success = await provider.updateOrder(widget.order!.id, data);
    } else {
      success = await provider.createOrder(data);
    }

    if (mounted) {
      setState(() => _isSaving = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing ? '订单已更新' : '订单已创建'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? '操作失败'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
