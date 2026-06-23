import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 订单编号生成器
///
/// 通过 Supabase RPC 调用 PostgreSQL 原子自增函数 [next_order_seq]，
/// 彻底杜绝并发竞态导致的重复订单号。
///
/// 格式: 2026-6-24-1  2026-6-24-2  ...
class OrderNoGenerator {
  /// 生成下一个订单编号（原子操作，并发安全）
  static Future<String> generate() async {
    final today = DateFormat('yyyy-M-d').format(DateTime.now());

    // 调用数据库原子自增函数
    // next_order_seq(p_date_key TEXT) → INTEGER
    final seq = await Supabase.instance.client
        .rpc('next_order_seq', params: {'p_date_key': today}) as int;

    return '$today-$seq';
  }
}
