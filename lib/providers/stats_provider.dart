import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/supabase_service.dart';

class StatsProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();

  bool _isLoading = true; // 初始加载态，避免首帧显示全 0
  String? _error;

  // 仪表盘数据
  int todayOrderCount = 0;
  int monthOrderCount = 0;
  int totalOrderCount = 0;
  double todayIncome = 0;
  double monthIncome = 0;
  double totalIncome = 0;
  double pendingPayment = 0;
  List<Order> recentOrders = [];

  // 财务统计
  List<Map<String, dynamic>> monthlyStats = [];

  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 加载仪表盘数据（单个查询失败不影响其余数据展示）
  Future<void> loadDashboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.todayOrderCount(),
        _service.monthOrderCount(),
        _service.totalOrderCount(),
        _service.todayIncome(),
        _service.monthIncome(),
        _service.totalIncome(),
        _service.pendingPayment(),
        _service.recentOrders(),
      ], eagerError: false); // 全部完成后再检查，不因一个失败而丢弃其余

      // 逐个降级：成功的用实际值，失败的用默认值
      todayOrderCount = _safeInt(results[0], 0);
      monthOrderCount = _safeInt(results[1], 0);
      totalOrderCount = _safeInt(results[2], 0);
      todayIncome = _safeDouble(results[3], 0);
      monthIncome = _safeDouble(results[4], 0);
      totalIncome = _safeDouble(results[5], 0);
      pendingPayment = _safeDouble(results[6], 0);
      recentOrders = results[7] is List<Order> ? results[7] as List<Order> : [];

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = '加载数据失败，请下拉刷新重试';
      notifyListeners();
    }
  }

  static int _safeInt(dynamic v, int fallback) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return fallback;
  }

  static double _safeDouble(dynamic v, double fallback) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return fallback;
  }

  /// 加载财务统计数据
  Future<void> loadMonthlyStats() async {
    _isLoading = true;
    notifyListeners();

    try {
      monthlyStats = await _service.monthlyStats();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = '加载统计数据失败';
      notifyListeners();
    }
  }
}
