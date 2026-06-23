import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_constants.dart';
import '../models/app_version.dart';
import '../models/order.dart';
import '../models/order_type.dart';

/// Supabase 数据访问层
///
/// 所有 **读操作** 内置 try-catch，失败时返回安全默认值（空列表/0/null），
/// 不会因单字段异常或网络抖动导致 UI 崩溃。
/// **写操作** 在 catch 中记录日志后重新抛出，由上层 Provider 统一处理。
class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // ============ 订单类型 ============

  /// 获取所有启用的订单类型
  Future<List<OrderType>> getOrderTypes() async {
    try {
      final result = await _client
          .from('order_types')
          .select()
          .eq('is_active', true)
          .order('sort_order');

      return result.map((e) => OrderType.fromJson(e)).toList();
    } catch (e) {
      debugPrint('❌ getOrderTypes: $e');
      return [];
    }
  }

  /// 新增订单类型
  Future<void> addOrderType(OrderType type) async {
    try {
      await _client.from('order_types').insert(type.toJson());
    } catch (e) {
      debugPrint('❌ addOrderType: $e');
      rethrow;
    }
  }

  /// 更新订单类型
  Future<void> updateOrderType(OrderType type) async {
    try {
      await _client.from('order_types').update(type.toJson()).eq('id', type.id);
    } catch (e) {
      debugPrint('❌ updateOrderType: $e');
      rethrow;
    }
  }

  /// 软删除订单类型
  Future<void> deleteOrderType(String id) async {
    try {
      await _client
          .from('order_types')
          .update({'is_active': false})
          .eq('id', id);
    } catch (e) {
      debugPrint('❌ deleteOrderType: $e');
      rethrow;
    }
  }

  // ============ 订单 ============

  /// 获取订单列表（支持筛选和搜索）
  Future<List<Order>> getOrders({
    String? status,
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      dynamic query = _client.from('orders').select();

      if (status != null && status.isNotEmpty) {
        query = query.eq('status', status);
      }

      if (search != null && search.isNotEmpty) {
        query = query.or(
          'customer_name.ilike.%$search%,order_no.ilike.%$search%,contact.ilike.%$search%',
        );
      }

      query = query
          .order('created_at', ascending: false)
          .limit(limit)
          .range(offset, offset + limit - 1);

      final result = await query;
      return result.map((e) => Order.fromJson(e)).toList();
    } catch (e) {
      debugPrint('❌ getOrders: $e');
      return [];
    }
  }

  /// 获取单个订单（not found 时返回 null）
  Future<Order?> getOrder(String id) async {
    try {
      final result =
          await _client.from('orders').select().eq('id', id).single();
      return Order.fromJson(result);
    } on PostgrestException catch (e) {
      // PGRST116 = 查询结果为空（.single() 无匹配）
      if (e.code == 'PGRST116') return null;
      debugPrint('❌ getOrder: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('❌ getOrder: $e');
      return null;
    }
  }

  /// 创建订单
  Future<void> createOrder(Map<String, dynamic> data) async {
    try {
      await _client.from('orders').insert(data);
    } catch (e) {
      debugPrint('❌ createOrder: $e');
      rethrow;
    }
  }

  /// 更新订单
  Future<void> updateOrder(String id, Map<String, dynamic> data) async {
    try {
      await _client.from('orders').update(data).eq('id', id);
    } catch (e) {
      debugPrint('❌ updateOrder: $e');
      rethrow;
    }
  }

  /// 删除订单
  Future<void> deleteOrder(String id) async {
    try {
      await _client.from('orders').delete().eq('id', id);
    } catch (e) {
      debugPrint('❌ deleteOrder: $e');
      rethrow;
    }
  }

  // ============ 统计 ============

  /// 今日订单数
  Future<int> todayOrderCount() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final result = await _client
          .from('orders')
          .select('id')
          .gte('created_at', '$today 00:00:00')
          .lte('created_at', '$today 23:59:59');
      return (result as List).length;
    } catch (e) {
      debugPrint('❌ todayOrderCount: $e');
      return 0;
    }
  }

  /// 本月订单数
  Future<int> monthOrderCount() async {
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1).toIso8601String();
      final result = await _client
          .from('orders')
          .select('id')
          .gte('created_at', start);
      return (result as List).length;
    } catch (e) {
      debugPrint('❌ monthOrderCount: $e');
      return 0;
    }
  }

  /// 累计订单数
  Future<int> totalOrderCount() async {
    try {
      final result = await _client.from('orders').select('id');
      return (result as List).length;
    } catch (e) {
      debugPrint('❌ totalOrderCount: $e');
      return 0;
    }
  }

  /// 今日收入（已收金额）
  Future<double> todayIncome() async {
    try {
      final today = DateTime.now().toIso8601String().split('T')[0];
      final result = await _client
          .from('orders')
          .select('paid_amount')
          .gte('created_at', '$today 00:00:00')
          .lte('created_at', '$today 23:59:59');
      double sum = 0;
      for (final r in result) {
        sum += _safeDouble(r['paid_amount']);
      }
      return sum;
    } catch (e) {
      debugPrint('❌ todayIncome: $e');
      return 0;
    }
  }

  /// 本月收入
  Future<double> monthIncome() async {
    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, 1).toIso8601String();
      final result = await _client
          .from('orders')
          .select('paid_amount')
          .gte('created_at', start);
      double sum = 0;
      for (final r in result) {
        sum += _safeDouble(r['paid_amount']);
      }
      return sum;
    } catch (e) {
      debugPrint('❌ monthIncome: $e');
      return 0;
    }
  }

  /// 累计收入
  Future<double> totalIncome() async {
    try {
      final result = await _client.from('orders').select('paid_amount');
      double sum = 0;
      for (final r in result) {
        sum += _safeDouble(r['paid_amount']);
      }
      return sum;
    } catch (e) {
      debugPrint('❌ totalIncome: $e');
      return 0;
    }
  }

  /// 待收款总额
  Future<double> pendingPayment() async {
    try {
      final result = await _client
          .from('orders')
          .select('total_amount, paid_amount')
          .neq('status', OrderStatus.cancelled);
      double sum = 0;
      for (final r in result) {
        final total = _safeDouble(r['total_amount']);
        final paid = _safeDouble(r['paid_amount']);
        sum += total - paid;
      }
      return sum;
    } catch (e) {
      debugPrint('❌ pendingPayment: $e');
      return 0;
    }
  }

  /// 最近订单列表
  Future<List<Order>> recentOrders({int limit = 10}) async {
    try {
      final result = await _client
          .from('orders')
          .select()
          .order('created_at', ascending: false)
          .limit(limit);

      return result.map((e) => Order.fromJson(e)).toList();
    } catch (e) {
      debugPrint('❌ recentOrders: $e');
      return [];
    }
  }

  // ============ 版本更新 ============

  /// 获取最新发布的版本信息
  Future<AppVersion?> getLatestVersion() async {
    try {
      final result = await _client
          .from('app_versions')
          .select()
          .order('version_code', ascending: false)
          .limit(1)
          .single();
      return AppVersion.fromJson(result);
    } catch (_) {
      return null;
    }
  }

  /// 按月统计收入
  Future<List<Map<String, dynamic>>> monthlyStats() async {
    try {
      final result =
          await _client.from('orders').select('paid_amount, created_at');

      final Map<String, double> monthMap = {};
      for (final r in result) {
        final paid = _safeDouble(r['paid_amount']);
        final dateStr = r['created_at'];
        if (dateStr == null) continue;
        try {
          final date = DateTime.parse(dateStr as String);
          final key =
              '${date.year}-${date.month.toString().padLeft(2, '0')}';
          monthMap[key] = (monthMap[key] ?? 0) + paid;
        } catch (_) {
          // 跳过日期格式异常的行
        }
      }

      return monthMap.entries
          .map((e) => {'month': e.key, 'amount': e.value})
          .toList()
        ..sort(
            (a, b) => (a['month'] as String).compareTo(b['month'] as String));
    } catch (e) {
      debugPrint('❌ monthlyStats: $e');
      return [];
    }
  }

  // ============ 内部工具 ============

  /// 安全地将动态值转为 double，null / 非数字 → 0
  static double _safeDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}
