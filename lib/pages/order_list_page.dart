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

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<OrderProvider>().loadOrders();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<OrderProvider>();
    final theme = Theme.of(context);

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
              onChanged: (value) {
                provider.loadOrders(
                  status: _selectedStatus,
                  search: value.isEmpty ? null : value,
                );
              },
              onClear: () {
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
                        subtitle: '点击右下角 + 创建新订单',
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
