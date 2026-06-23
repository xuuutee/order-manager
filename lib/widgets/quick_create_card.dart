import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_constants.dart';
import '../providers/order_provider.dart';
import '../providers/order_type_provider.dart';
import '../providers/stats_provider.dart';
import '../utils/order_no_generator.dart';

/// 仪表盘内嵌的快速发布订单卡片
class QuickCreateCard extends StatefulWidget {
  const QuickCreateCard({super.key});

  @override
  State<QuickCreateCard> createState() => _QuickCreateCardState();
}

class _QuickCreateCardState extends State<QuickCreateCard> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _customerNameCtrl;
  late final TextEditingController _contactCtrl;
  late final TextEditingController _totalAmountCtrl;
  late final TextEditingController _managerCtrl;
  late final TextEditingController _remarkCtrl;

  String? _orderTypeId;
  DateTime? _deadline;
  bool _showMore = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _customerNameCtrl = TextEditingController();
    _contactCtrl = TextEditingController();
    _totalAmountCtrl = TextEditingController();
    _managerCtrl = TextEditingController();
    _remarkCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _customerNameCtrl.dispose();
    _contactCtrl.dispose();
    _totalAmountCtrl.dispose();
    _managerCtrl.dispose();
    _remarkCtrl.dispose();
    super.dispose();
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _customerNameCtrl.clear();
    _contactCtrl.clear();
    _totalAmountCtrl.clear();
    _managerCtrl.clear();
    _remarkCtrl.clear();
    setState(() {
      _orderTypeId = null;
      _deadline = null;
      _showMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typeProvider = context.watch<OrderTypeProvider>();
    final orderTypes = typeProvider.types;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 标题栏
              Row(
                children: [
                  Icon(Icons.add_circle_outline,
                      size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    '快速发布',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _save,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send, size: 18),
                    label:
                        Text(_isSaving ? '发布中...' : '发布'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // === 核心必填字段 ===
              TextFormField(
                controller: _customerNameCtrl,
                decoration: const InputDecoration(
                  labelText: '客户昵称 *',
                  hintText: '微信昵称或客户称呼',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? '请输入客户昵称' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _totalAmountCtrl,
                      decoration: const InputDecoration(
                        labelText: '订单金额 *',
                        prefixText: '¥ ',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return '请输入金额';
                        }
                        if (double.tryParse(v) == null) {
                          return '无效金额';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _orderTypeId,
                      decoration: const InputDecoration(
                        labelText: '订单类型',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      hint: const Text('选择类型', style: TextStyle(fontSize: 14)),
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
              const SizedBox(height: 8),

              // === 更多信息 折叠区 ===
              InkWell(
                onTap: () => setState(() => _showMore = !_showMore),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showMore
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 18,
                        color: theme.colorScheme.onSurface.withAlpha(153),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '更多信息',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withAlpha(153),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '联系方式、负责人、备注…',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withAlpha(102),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (_showMore) ...[
                const SizedBox(height: 4),
                TextFormField(
                  controller: _contactCtrl,
                  decoration: const InputDecoration(
                    labelText: '联系方式',
                    hintText: '手机号 / 微信号',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _managerCtrl,
                  decoration: const InputDecoration(
                    labelText: '负责人',
                    hintText: '负责此订单的成员',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 10),
                _buildDateField(
                  label: '截止时间',
                  date: _deadline,
                  onPicked: (d) => setState(() => _deadline = d),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _remarkCtrl,
                  decoration: const InputDecoration(
                    labelText: '备注',
                    hintText: '订单备注信息…',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  maxLines: 2,
                  textInputAction: TextInputAction.newline,
                ),
              ],
            ],
          ),
        ),
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
          isDense: true,
          suffixIcon:
              const Icon(Icons.calendar_today, size: 18),
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
    final orderNo = await OrderNoGenerator.generate();

    final data = {
      'order_no': orderNo,
      'customer_name': _customerNameCtrl.text.trim(),
      'contact': _contactCtrl.text.trim(),
      'order_type_id': _orderTypeId,
      'total_amount': double.tryParse(_totalAmountCtrl.text) ?? 0,
      'paid_amount': 0, // 新建默认 0
      'manager': _managerCtrl.text.trim(),
      'start_date': DateTime.now().toIso8601String(),
      'deadline': _deadline?.toIso8601String(),
      'status': OrderStatus.pending, // 新建默认"待处理"
      'remark': _remarkCtrl.text.trim(),
    };

    setState(() => _isSaving = true);

    final provider = context.read<OrderProvider>();
    final success = await provider.createOrder(data);

    if (mounted) {
      setState(() => _isSaving = false);

      if (success) {
        _resetForm();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('订单已创建'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
        // 刷新仪表盘统计数据
        context.read<StatsProvider>().loadDashboard();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? '创建失败'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
