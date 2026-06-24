import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/supabase_service.dart';

class StatsProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();

  bool _isLoading = false;
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

  /// 加载仪表盘数据
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
      ]);

      todayOrderCount = results[0] as int;
      monthOrderCount = results[1] as int;
      totalOrderCount = results[2] as int;
      todayIncome = results[3] as double;
      monthIncome = results[4] as double;
      totalIncome = results[5] as double;
      pendingPayment = results[6] as double;
      recentOrders = results[7] as List<Order>;

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = '加载数据失败，请下拉刷新重试';
      notifyListeners();
    }
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
