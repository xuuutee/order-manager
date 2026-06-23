import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 订单编号生成器
/// 格式: 2026-6-22-1  2026-6-22-2  ...
class OrderNoGenerator {
  /// 生成下一个订单编号
  static Future<String> generate() async {
    final today = DateFormat('yyyy-M-d').format(DateTime.now());

    // 查询今天已创建的最大序号
    final result = await Supabase.instance.client
        .from('orders')
        .select('order_no')
        .like('order_no', '$today-%')
        .order('created_at', ascending: false)
        .limit(1);

    if (result.isEmpty) {
      return '$today-1';
    }

    final lastNo = result[0]['order_no'] as String;
    final parts = lastNo.split('-');
    final lastSeq = int.tryParse(parts.last) ?? 0;

    return '$today-${lastSeq + 1}';
  }
}
