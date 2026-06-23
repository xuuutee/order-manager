import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/stats_provider.dart';
import '../utils/currency_formatter.dart';
import '../widgets/stat_card.dart';
import '../widgets/loading_indicator.dart';

class FinanceStatsPage extends StatefulWidget {
  const FinanceStatsPage({super.key});

  @override
  State<FinanceStatsPage> createState() => _FinanceStatsPageState();
}

class _FinanceStatsPageState extends State<FinanceStatsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final stats = context.read<StatsProvider>();
      stats.loadDashboard();
      stats.loadMonthlyStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = context.watch<StatsProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('财务统计'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              stats.loadDashboard();
              stats.loadMonthlyStats();
            },
          ),
        ],
      ),
      body: stats.isLoading
          ? const LoadingIndicator(message: '加载中...')
          : RefreshIndicator(
              onRefresh: () async {
                await Future.wait([
                  stats.loadDashboard(),
                  stats.loadMonthlyStats(),
                ]);
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ===== 总览卡片 =====
                  _sectionTitle('总览', theme),
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
                        title: '总营业额',
                        value: CurrencyFormatter.formatCompact(
                            stats.totalIncome + stats.pendingPayment),
                        icon: Icons.account_balance_wallet,
                        iconColor: theme.colorScheme.primary,
                      ),
                      StatCard(
                        title: '已收金额',
                        value: CurrencyFormatter.formatCompact(
                            stats.totalIncome),
                        icon: Icons.check_circle,
                        iconColor: Colors.green,
                      ),
                      StatCard(
                        title: '待收金额',
                        value: CurrencyFormatter.formatCompact(
                            stats.pendingPayment),
                        icon: Icons.pending_actions,
                        iconColor: theme.colorScheme.error,
                      ),
                      StatCard(
                        title: '订单总数',
                        value: '${stats.totalOrderCount}',
                        icon: Icons.receipt_long,
                        iconColor: theme.colorScheme.secondary,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 平均客单价（横条）
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.trending_up,
                              color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '平均客单价',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withAlpha(153),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                stats.totalOrderCount > 0
                                    ? CurrencyFormatter.format(
                                        (stats.totalIncome + stats.pendingPayment) /
                                            stats.totalOrderCount)
                                    : '¥0.00',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            '基于${stats.totalOrderCount}笔订单',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withAlpha(102),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ===== 月度收入图表 =====
                  _sectionTitle('月度收入', theme),
                  const SizedBox(height: 4),
                  Text(
                    '已收金额（按月统计）',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(153),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMonthlyChart(stats, theme),

                  const SizedBox(height: 24),

                  // ===== 月度收入明细 =====
                  _sectionTitle('月度明细', theme),
                  const SizedBox(height: 8),
                  if (stats.monthlyStats.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            '暂无收入数据',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface
                                  .withAlpha(102),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    Card(
                      child: Column(
                        children: stats.monthlyStats.reversed.map((item) {
                          final month = item['month'] as String;
                          final amount = item['amount'] as double;
                          final isLast = item == stats.monthlyStats.last;

                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Text(
                                      _formatMonth(month),
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    const Spacer(),
                                    Text(
                                      CurrencyFormatter.format(amount),
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isLast)
                                Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                  color: theme.colorScheme.outlineVariant,
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),

                  const SizedBox(height: 40),
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

  // ========== 月度柱状图 ==========
  Widget _buildMonthlyChart(StatsProvider stats, ThemeData theme) {
    if (stats.monthlyStats.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('暂无数据')),
      );
    }

    // 最多展示最近 12 个月
    final data = stats.monthlyStats.length > 12
        ? stats.monthlyStats.sublist(stats.monthlyStats.length - 12)
        : stats.monthlyStats;

    final maxAmount = data
        .map((e) => e['amount'] as double)
        .reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxAmount * 1.2,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final month = data[groupIndex]['month'] as String;
                    final amount = rod.toY;
                    return BarTooltipItem(
                      '${_formatMonth(month)}\n${CurrencyFormatter.format(amount)}',
                      TextStyle(
                        color: theme.colorScheme.onInverseSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= data.length) {
                        return const SizedBox.shrink();
                      }
                      final month = data[idx]['month'] as String;
                      final parts = month.split('-');
                      final label = '${parts[1]}月';
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface
                                .withAlpha(153),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) {
                      if (value == 0) return const SizedBox.shrink();
                      return Text(
                        '¥${(value / 1000).toStringAsFixed(0)}k',
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurface
                              .withAlpha(102),
                        ),
                      );
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxAmount > 0 ? maxAmount / 4 : 1,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: theme.colorScheme.outlineVariant.withAlpha(80),
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(show: false),
              barGroups: data.asMap().entries.map((entry) {
                final idx = entry.key;
                final amount = entry.value['amount'] as double;
                return BarChartGroupData(
                  x: idx,
                  barRods: [
                    BarChartRodData(
                      toY: amount,
                      color: theme.colorScheme.primary,
                      width: 18,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  String _formatMonth(String monthKey) {
    // monthKey 格式: "2026-06"
    final parts = monthKey.split('-');
    if (parts.length != 2) return monthKey;
    return '${parts[0]}年${int.parse(parts[1])}月';
  }
}
