import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import '../models/order_type.dart';
import '../utils/http_retry.dart';

/// Supabase 数据访问层（带重试和超时容错）
class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // ============ 订单类型 ============

  /// 获取所有启用的订单类型
  Future<List<OrderType>> getOrderTypes() async {
    return HttpRetry.execute(
      operation: () async {
        final result = await _client
            .from('order_types')
            .select()
            .eq('is_active', true)
            .order('sort_order');

        return result.map((e) => OrderType.fromJson(e)).toList();
      },
    );
  }

  /// 新增订单类型
  Future<void> addOrderType(OrderType type) async {
    await _client.from('order_types').insert(type.toJson());
  }

  /// 更新订单类型
  Future<void> updateOrderType(OrderType type) async {
    await _client.from('order_types').update(type.toJson()).eq('id', type.id);
  }

  /// 软删除订单类型
  Future<void> deleteOrderType(String id) async {
    await _client
        .from('order_types')
        .update({'is_active': false})
        .eq('id', id);
  }

  // ============ 订单 ============

  /// 获取订单列表（支持筛选和搜索）
  Future<List<Order>> getOrders({
    String? status,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    return HttpRetry.execute(
      operation: () async {
        var query = _client.from('orders').select('*');

        if (status != null && status.isNotEmpty) {
          query = query.eq('status', status);
        }

        if (search != null && search.isNotEmpty) {
          query = query.or(
            'customer_name.ilike.%$search%,order_no.ilike.%$search%,contact.ilike.%$search%',
          );
        }

        final result = await query
            .order('created_at', ascending: false)
            .limit(limit)
            .range(offset, offset + limit - 1);

        return result.map((e) => Order.fromJson(e)).toList();
      },
    );
  }

  /// 获取单个订单
  Future<Order?> getOrder(String id) async {
    return HttpRetry.execute(
      operation: () async {
        final result = await _client
            .from('orders')
            .select('*')
            .eq('id', id)
            .single();
        return Order.fromJson(result);
      },
    );
  }

  /// 创建订单
  Future<void> createOrder(Map<String, dynamic> data) async {
    await HttpRetry.execute(
      operation: () => _client.from('orders').insert(data),
    );
  }

  /// 更新订单
  Future<void> updateOrder(String id, Map<String, dynamic> data) async {
    await HttpRetry.execute(
      operation: () => _client.from('orders').update(data).eq('id', id),
    );
  }

  /// 删除订单
  Future<void> deleteOrder(String id) async {
    await HttpRetry.execute(
      operation: () => _client.from('orders').delete().eq('id', id),
    );
  }

  /// 今日订单数
  Future<int> todayOrderCount() async {
    return HttpRetry.execute(
      operation: () async {
        final today = DateTime.now().toIso8601String().split('T')[0];
        final result = await _client
            .from('orders')
            .select('id')
            .gte('created_at', '$today 00:00:00')
            .lte('created_at', '$today 23:59:59');
        return (result as List).length;
      },
    );
  }

  /// 本月订单数
  Future<int> monthOrderCount() async {
    return HttpRetry.execute(
      operation: () async {
        final now = DateTime.now();
        final start = DateTime(now.year, now.month, 1).toIso8601String();
        final result = await _client
            .from('orders')
            .select('id')
            .gte('created_at', start);
        return (result as List).length;
      },
    );
  }

  /// 累计订单数
  Future<int> totalOrderCount() async {
    return HttpRetry.execute(
      operation: () async {
        final result = await _client.from('orders').select('id');
        return (result as List).length;
      },
    );
  }

  /// 今日收入（已收金额）
  Future<double> todayIncome() async {
    return HttpRetry.execute(
      operation: () async {
        final today = DateTime.now().toIso8601String().split('T')[0];
        final result = await _client
            .from('orders')
            .select('paid_amount')
            .gte('created_at', '$today 00:00:00')
            .lte('created_at', '$today 23:59:59');
        double sum = 0;
        for (final r in result) {
          sum += (r['paid_amount'] as num).toDouble();
        }
        return sum;
      },
    );
  }

  /// 本月收入
  Future<double> monthIncome() async {
    return HttpRetry.execute(
      operation: () async {
        final now = DateTime.now();
        final start = DateTime(now.year, now.month, 1).toIso8601String();
        final result = await _client
            .from('orders')
            .select('paid_amount')
            .gte('created_at', start);
        double sum = 0;
        for (final r in result) {
          sum += (r['paid_amount'] as num).toDouble();
        }
        return sum;
      },
    );
  }

  /// 累计收入
  Future<double> totalIncome() async {
    return HttpRetry.execute(
      operation: () async {
        final result = await _client.from('orders').select('paid_amount');
        double sum = 0;
        for (final r in result) {
          sum += (r['paid_amount'] as num).toDouble();
        }
        return sum;
      },
    );
  }

  /// 待收款总额
  Future<double> pendingPayment() async {
    return HttpRetry.execute(
      operation: () async {
        final result = await _client
            .from('orders')
            .select('total_amount, paid_amount')
            .neq('status', '已取消');
        double sum = 0;
        for (final r in result) {
          final total = (r['total_amount'] as num).toDouble();
          final paid = (r['paid_amount'] as num).toDouble();
          sum += total - paid;
        }
        return sum;
      },
    );
  }

  /// 最近订单列表
  Future<List<Order>> recentOrders({int limit = 10}) async {
    return HttpRetry.execute(
      operation: () async {
        final result = await _client
            .from('orders')
            .select()
            .order('created_at', ascending: false)
            .limit(limit);

        return result.map((e) => Order.fromJson(e)).toList();
      },
    );
  }

  /// 按月统计收入
  Future<List<Map<String, dynamic>>> monthlyStats() async {
    return HttpRetry.execute(
      operation: () async {
        final result = await _client.from('orders').select('paid_amount, created_at');

        // 在客户端按月聚合
        final Map<String, double> monthMap = {};
        for (final r in result) {
          final paid = (r['paid_amount'] as num).toDouble();
          final date = DateTime.parse(r['created_at'] as String);
          final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
          monthMap[key] = (monthMap[key] ?? 0) + paid;
        }

        return monthMap.entries
            .map((e) => {'month': e.key, 'amount': e.value})
            .toList()
          ..sort((a, b) => (a['month'] as String).compareTo(b['month'] as String));
      },
    );
  }
}
