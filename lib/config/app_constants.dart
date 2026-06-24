/// 订单状态常量
class OrderStatus {
  static const pending = '待处理';
  static const inProgress = '进行中';
  static const completed = '已完成';
  static const settled = '已结算';
  static const cancelled = '已取消';

  static const all = [pending, inProgress, completed, settled, cancelled];

  /// 状态对应的显示颜色（用于状态标签）
  static const colors = {
    pending: 0xFFFFA726,    // 橙色
    inProgress: 0xFF42A5F5, // 蓝色
    completed: 0xFF66BB6A,  // 绿色
    settled: 0xFFAB47BC,    // 紫色
    cancelled: 0xFF757575,  // 灰色
  };
}
