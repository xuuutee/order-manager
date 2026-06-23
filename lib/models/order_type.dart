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
      id: _safeString(json['id']),
      name: _safeString(json['name'], fallback: '未命名'),
      sortOrder: _safeInt(json['sort_order']),
      isActive: json['is_active'] is bool ? json['is_active'] as bool : true,
      createdAt: _safeDateTime(json['created_at']) ?? DateTime.now(),
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

  static String _safeString(dynamic v, {String fallback = ''}) {
    if (v == null) return fallback;
    if (v is String) return v;
    return v.toString();
  }

  static int _safeInt(dynamic v, {int fallback = 0}) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? fallback;
    return fallback;
  }

  static DateTime? _safeDateTime(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}
