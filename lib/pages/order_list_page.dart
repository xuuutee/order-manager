import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/app_constants.dart';
import '../providers/order_provider.dart';
import '../widgets/order_card.dart';
import '../widgets/search_bar.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';
import 'order_detail_page.dart';

class OrderListPage extends StatefulWidget {
  const OrderListPage({super.key});

  @override
  State<OrderListPage> createState() => _OrderListPageState();
}

class _OrderListPageState extends State<OrderListPage> {
  final _searchController = TextEditingController();
  String? _selectedStatus;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<OrderProvider>().loadOrders();
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// 防抖搜索：300ms 内无新输入才触发查询
  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      context.read<OrderProvider>().loadOrders(
            status: _selectedStatus,
            search: value.isEmpty ? null : value,
          );
    });
  }

  /// 同步本地筛选 UI 与 provider 状态（create 后会清空筛选）
  void _syncFiltersFromProvider(OrderProvider provider) {
    if (_selectedStatus != null && provider.statusFilter == null) {
      _selectedStatus = null;
    }
    if (_searchController.text.isNotEmpty && provider.searchQuery == null) {
      _searchController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final theme = Theme.of(context);

    // 确保本地筛选状态与 provider 一致
    _syncFiltersFromProvider(provider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('订单管理'),
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: AppSearchBar(
              controller: _searchController,
              hintText: '搜索订单编号、客户名、联系方式...',
              onChanged: _onSearchChanged,
              onClear: () {
                _debounceTimer?.cancel();
                provider.loadOrders(status: _selectedStatus);
              },
            ),
          ),

          // 状态筛选标签
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildFilterChip('全部', null, theme),
                ...OrderStatus.all.map(
                  (s) => _buildFilterChip(s, s, theme),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 订单列表
          Expanded(
            child: provider.isLoading
                ? const LoadingIndicator()
                : provider.orders.isEmpty
                    ? const EmptyState(
                        icon: Icons.receipt_long,
                        title: '暂无订单',
                        subtitle: '点击右下角 + 发布新订单',
                      )
                    : RefreshIndicator(
                        onRefresh: () => provider.loadOrders(
                          status: _selectedStatus,
                          search: _searchController.text.isEmpty
                              ? null
                              : _searchController.text,
                        ),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: provider.orders.length,
                          itemBuilder: (context, index) {
                            final order = provider.orders[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: RepaintBoundary(
                                child: OrderCard(
                                  order: order,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => OrderDetailPage(
                                          orderId: order.id,
                                        ),
                                      ),
                                    );
                                  },
                                  onComplete: () async {
                                    final provider =
                                        context.read<OrderProvider>();
                                    final success = await provider
                                        .updateStatus(order.id, '已完成');
                                    if (success && mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('订单已标记为完成'),
                                          behavior:
                                              SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                  onUncomplete: () async {
                                    final provider =
                                        context.read<OrderProvider>();
                                    final success = await provider
                                        .updateStatus(order.id, '待处理');
                                    if (success && mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content:
                                              Text('订单已恢复为待处理'),
                                          behavior:
                                              SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? status, ThemeData theme) {
    final isSelected = _selectedStatus == status;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          _debounceTimer?.cancel();
          setState(() {
            _selectedStatus = selected ? status : null;
          });
          context.read<OrderProvider>().loadOrders(
                status: _selectedStatus,
                search: _searchController.text.isEmpty
                    ? null
                    : _searchController.text,
              );
        },
        showCheckmark: false,
        selectedColor: theme.colorScheme.primaryContainer,
        labelStyle: TextStyle(
          fontSize: 13,
          color: isSelected
              ? theme.colorScheme.onPrimaryContainer
              : theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
