import 'package:flutter/foundation.dart';
import '../models/order_type.dart';
import '../services/supabase_service.dart';

class OrderTypeProvider extends ChangeNotifier {
  final SupabaseService _service = SupabaseService();

  List<OrderType> _types = [];
  bool _isLoading = false;
  String? _error;

  List<OrderType> get types => _types;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 加载订单类型列表
  Future<void> loadTypes() async {
    _isLoading = true;
    notifyListeners();

    try {
      _types = await _service.getOrderTypes();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = '加载订单类型失败';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 根据名称获取类型ID
  String getTypeIdByName(String name) {
    final type = _types.where((t) => t.name == name).firstOrNull;
    return type?.id ?? '';
  }

  /// 根据ID获取类型名称
  String getTypeNameById(String id) {
    final type = _types.where((t) => t.id == id).firstOrNull;
    return type?.name ?? '未知';
  }
}
