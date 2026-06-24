import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/stats_provider.dart';
import '../utils/currency_formatter.dart';
import '../widgets/stat_card.dart';
import '../widgets/order_card.dart';
import '../widgets/empty_state.dart';
import '../widgets/loading_indicator.dart';
import 'order_detail_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // 首次加载
    Future.microtask(() {
      context.read<StatsProvider>().loadDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('工作台'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => stats.loadDashboard(),
          ),
        ],
      ),
      body: stats.isLoading
          ? const LoadingIndicator(message: '加载中...')
          : RefreshIndicator(
              onRefresh: () => stats.loadDashboard(),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ===== 订单统计卡片区 =====
                  _sectionTitle('订单统计', theme),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.6,
                    children: [
                      StatCard(
                        title: '今日订单',
                        value: '${stats.todayOrderCount}',
                        icon: Icons.today,
                        iconColor: theme.colorScheme.primary,
                      ),
                      StatCard(
                        title: '本月订单',
                        value: '${stats.monthOrderCount}',
                        icon: Icons.calendar_month,
                        iconColor: theme.colorScheme.tertiary,
                      ),
                      StatCard(
                        title: '累计订单',
                        value: '${stats.totalOrderCount}',
                        icon: Icons.inventory_2,
                        iconColor: theme.colorScheme.secondary,
                      ),
                      StatCard(
                        title: '待收款',
                        value: CurrencyFormatter.formatCompact(
                            stats.pendingPayment),
                        icon: Icons.pending_actions,
                        iconColor: theme.colorScheme.error,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ===== 收入统计卡片区 =====
                  _sectionTitle('收入统计', theme),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.6,
                    children: [
                      StatCard(
                        title: '今日收入',
                        value: CurrencyFormatter.formatCompact(
                            stats.todayIncome),
                        icon: Icons.attach_money,
                        iconColor: Colors.green,
                      ),
                      StatCard(
                        title: '本月收入',
                        value: CurrencyFormatter.formatCompact(
                            stats.monthIncome),
                        icon: Icons.trending_up,
                        iconColor: Colors.blue,
                      ),
                      StatCard(
                        title: '累计收入',
                        value: CurrencyFormatter.formatCompact(
                            stats.totalIncome),
                        icon: Icons.account_balance_wallet,
                        iconColor: Colors.deepPurple,
                      ),
                      StatCard(
                        title: '平均客单价',
                        value: stats.totalOrderCount > 0
                            ? CurrencyFormatter.formatCompact(
                                stats.totalIncome / stats.totalOrderCount)
                            : '¥0',
                        icon: Icons.bar_chart,
                        iconColor: Colors.orange,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ===== 最近订单 =====
                  _sectionTitle('最近订单', theme),
                  const SizedBox(height: 8),
                  if (stats.recentOrders.isEmpty)
                    const EmptyState(
                      icon: Icons.receipt_long,
                      title: '暂无订单',
                      subtitle: '点击右下角 + 创建第一个订单',
                    )
                  else
                    ...stats.recentOrders.map(
                      (order) => Padding(
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
                      ),
                    ),

                  const SizedBox(height: 80), // 底部留白给 FAB
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
