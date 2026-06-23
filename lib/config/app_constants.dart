/// 订单状态常量
class OrderStatus {
  static const published = '已发布';   // 管理者发布后的初始状态
  static const pending = '待处理';     // 兼容旧数据
  static const inProgress = '进行中';
  static const completed = '已完成';
  static const settled = '已结算';
  static const cancelled = '已取消';

  static const all = [published, pending, inProgress, completed, settled, cancelled];

  /// 状态对应的显示颜色（用于状态标签）
  static const colors = {
    published: 0xFF5C6BC0,  // 靛蓝色（品牌色）
    pending: 0xFFFFA726,    // 橙色（兼容旧数据）
    inProgress: 0xFF42A5F5, // 蓝色
    completed: 0xFF66BB6A,  // 绿色
    settled: 0xFFAB47BC,    // 紫色
    cancelled: 0xFF757575,  // 灰色
  };
}
