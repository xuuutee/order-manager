import 'dart:math';

/// 订单编号生成器
///
/// 格式: YYYYMMDD-HHmmss-XXXX
/// 示例: 20260624-201530-a3f2
///
/// 不依赖数据库查询，无竞态条件，并发安全。
class OrderNoGenerator {
  static final _random = Random.secure();
  static const _chars = 'abcdefghijklmnopqrstuvwxyz0123456789';

  /// 生成订单编号
  static String generate() {
    final now = DateTime.now();
    final datePart = '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    final timePart = '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';

    // 4 位随机后缀 — 36^4 = 1,679,616 种可能，足够防冲突
    final suffix = List.generate(4, (_) => _chars[_random.nextInt(_chars.length)]).join();

    return '$datePart-$timePart-$suffix';
  }
}
