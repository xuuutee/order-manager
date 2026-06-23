import 'package:flutter/foundation.dart';
import '../models/order.dart';
import '../services/supabase_service.dart';

class OrderProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();

  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;
  String? _statusFilter;
  String? _searchQuery;

  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get statusFilter => _statusFilter;
  String? get searchQuery => _searchQuery;

  /// 加载订单列表
  Future<void> loadOrders({String? status, String? search}) async {
    _statusFilter = status;
    _searchQuery = search;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _orders = await _service.getOrders(
        status: status,
        search: search,
      );
      _isLoading = false;
    } catch (e) {
      _isLoading = false;
      _error = '加载订单失败';
    }
    notifyListeners(); // 只通知一次
  }

  /// 获取单个订单（用于详情页刷新）
  Future<Order?> fetchOrderById(String id) async {
    try {
      return await _service.getOrder(id);
    } catch (_) {
      return null;
    }
  }

  /// 创建订单（创建后清空筛选，确保新订单可见）
  Future<bool> createOrder(Map<String, dynamic> data) async {
    try {
      await _service.createOrder(data);
      // 清空筛选重新加载，确保新订单一定出现在列表中
      _statusFilter = null;
      _searchQuery = null;
      await loadOrders();
      return true;
    } catch (e) {
      _error = '创建订单失败: $e';
      debugPrint('❌ createOrder error: $e');
      notifyListeners();
      return false;
    }
  }

  /// 更新订单（优先局部更新，fallback 时清空筛选确保可见）
  Future<bool> updateOrder(String id, Map<String, dynamic> data) async {
    try {
      await _service.updateOrder(id, data);
      // 优先局部更新列表中的订单
      final index = _orders.indexWhere((o) => o.id == id);
      if (index != -1) {
        final updated = await _service.getOrder(id);
        if (updated != null) {
          _orders[index] = updated;
          notifyListeners();
          return true;
        }
      }
      // fallback：清空筛选后完整重载
      _statusFilter = null;
      _searchQuery = null;
      await loadOrders();
      return true;
    } catch (e) {
      _error = '更新订单失败: $e';
      debugPrint('❌ updateOrder error: $e');
      notifyListeners();
      return false;
    }
  }

  /// 更新订单状态
  Future<bool> updateStatus(String id, String newStatus) async {
    return updateOrder(id, {'status': newStatus});
  }

  /// 更新已收金额
  Future<bool> updatePaidAmount(String id, double paidAmount) async {
    return updateOrder(id, {'paid_amount': paidAmount});
  }

  /// 删除订单（局部移除，避免完整重载）
  Future<bool> deleteOrder(String id) async {
    try {
      await _service.deleteOrder(id);
      _orders.removeWhere((o) => o.id == id);
      _error = null;
      notifyListeners();
      return true;
    } catch (e) {
      _error = '删除订单失败';
      notifyListeners();
      return false;
    }
  }
}
