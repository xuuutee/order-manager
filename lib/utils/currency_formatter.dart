import 'package:intl/intl.dart';

/// 金额格式化工具
class CurrencyFormatter {
  static final NumberFormat _fmt = NumberFormat.currency(
    symbol: '¥',
    decimalDigits: 2,
  );

  /// 格式化金额，如 ¥1,280.00
  static String format(double amount) {
    return _fmt.format(amount);
  }

  /// 格式化金额，不带小数（整数时）
  static String formatCompact(double amount) {
    if (amount == amount.roundToDouble()) {
      return '¥${amount.toInt()}';
    }
    return _fmt.format(amount);
  }
}
