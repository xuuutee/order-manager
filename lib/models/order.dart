class Order {
  final String id;
  final String orderNo;
  final String customerName;
  final String contact;
  final String orderTypeId;
  final double totalAmount;
  final double paidAmount;
  final String manager;
  final DateTime? startDate;
  final DateTime? deadline;
  final String status;
  final String remark;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Order({
    required this.id,
    required this.orderNo,
    required this.customerName,
    required this.contact,
    required this.orderTypeId,
    required this.totalAmount,
    required this.paidAmount,
    required this.manager,
    this.startDate,
    this.deadline,
    required this.status,
    required this.remark,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 计算未收金额
  double get unpaidAmount => totalAmount - paidAmount;

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      orderNo: json['order_no'] as String,
      customerName: json['customer_name'] as String,
      contact: (json['contact'] as String?) ?? '',
      orderTypeId: (json['order_type_id'] as String?) ?? '',
      totalAmount: _toDouble(json['total_amount']),
      paidAmount: _toDouble(json['paid_amount']),
      manager: (json['manager'] as String?) ?? '',
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'] as String)
          : null,
      deadline: json['deadline'] != null
          ? DateTime.tryParse(json['deadline'] as String)
          : null,
      status: (json['status'] as String?) ?? '已发布',
      remark: (json['remark'] as String?) ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_no': orderNo,
      'customer_name': customerName,
      'contact': contact,
      'order_type_id': orderTypeId.isEmpty ? null : orderTypeId,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'manager': manager,
      'start_date': startDate?.toIso8601String(),
      'deadline': deadline?.toIso8601String(),
      'status': status,
      'remark': remark,
    };
  }

  Order copyWith({
    String? id,
    String? orderNo,
    String? customerName,
    String? contact,
    String? orderTypeId,
    double? totalAmount,
    double? paidAmount,
    String? manager,
    DateTime? startDate,
    DateTime? deadline,
    String? status,
    String? remark,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Order(
      id: id ?? this.id,
      orderNo: orderNo ?? this.orderNo,
      customerName: customerName ?? this.customerName,
      contact: contact ?? this.contact,
      orderTypeId: orderTypeId ?? this.orderTypeId,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      manager: manager ?? this.manager,
      startDate: startDate ?? this.startDate,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      remark: remark ?? this.remark,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0.0;
    return 0.0;
  }
}
