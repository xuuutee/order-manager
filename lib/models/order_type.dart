class OrderType {
  final String id;
  final String name;
  final int sortOrder;
  final bool isActive;
  final DateTime createdAt;

  const OrderType({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.isActive,
    required this.createdAt,
  });

  factory OrderType.fromJson(Map<String, dynamic> json) {
    return OrderType(
      id: json['id'] as String,
      name: json['name'] as String,
      sortOrder: (json['sort_order'] as num).toInt(),
      isActive: json['is_active'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'sort_order': sortOrder,
      'is_active': isActive,
    };
  }

  OrderType copyWith({
    String? id,
    String? name,
    int? sortOrder,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return OrderType(
      id: id ?? this.id,
      name: name ?? this.name,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
