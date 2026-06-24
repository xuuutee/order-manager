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
    notifyListeners();

    try {
      _orders = await _service.getOrders(
        status: status,
        search: search,
      );
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = '加载订单失败';
      notifyListeners();
    }
  }

  /// 创建订单
  Future<bool> createOrder(Map<String, dynamic> data) async {
    try {
      await _service.createOrder(data);
      await loadOrders(status: _statusFilter, search: _searchQuery);
      return true;
    } catch (e) {
      _error = '创建订单失败';
      notifyListeners();
      return false;
    }
  }

  /// 更新订单
  Future<bool> updateOrder(String id, Map<String, dynamic> data) async {
    try {
      await _service.updateOrder(id, data);
      await loadOrders(status: _statusFilter, search: _searchQuery);
      return true;
    } catch (e) {
      _error = '更新订单失败';
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
    final order = _orders.where((o) => o.id == id).firstOrNull;
    if (order == null) return false;
    return updateOrder(id, {'paid_amount': paidAmount});
  }

  /// 删除订单
  Future<bool> deleteOrder(String id) async {
    try {
      await _service.deleteOrder(id);
      await loadOrders(status: _statusFilter, search: _searchQuery);
      return true;
    } catch (e) {
      _error = '删除订单失败';
      notifyListeners();
      return false;
    }
  }
}
