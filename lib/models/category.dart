enum CategoryType { income, expense }

class CategoryModel {
  final String? id;
  final String name;
  final String? icon;
  final String? color;
  final CategoryType type;
  final String userId;
  final DateTime createdAt;

  CategoryModel({
    this.id,
    required this.name,
    this.icon,
    this.color,
    required this.type,
    required this.userId,
    required this.createdAt,
  });

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    CategoryType categoryType;
    final typeValue = map['type'];
    if (typeValue == 'income') {
      categoryType = CategoryType.income;
    } else if (typeValue == 'expense') {
      categoryType = CategoryType.expense;
    } else {
      categoryType = CategoryType.expense; // default
    }

    DateTime createdAtDate;
    try {
      final createdAtValue = map['created_at'];
      if (createdAtValue != null) {
        createdAtDate = DateTime.parse(createdAtValue.toString());
      } else {
        createdAtDate = DateTime.now();
      }
    } catch (e) {
      print('CategoryModel createdAt parse error: $e');
      createdAtDate = DateTime.now();
    }

    final nameValue = map['name'];
    final userIdValue = map['user_id'];
    final idValue = map['id'];
    final iconValue = map['icon'];
    final colorValue = map['color'];

    return CategoryModel(
      id: idValue != null ? idValue.toString() : null,
      name: nameValue != null ? nameValue.toString() : 'Kategori',
      icon: iconValue != null ? iconValue.toString() : null,
      color: colorValue != null ? colorValue.toString() : null,
      type: categoryType,
      userId: userIdValue != null ? userIdValue.toString() : '',
      createdAt: createdAtDate,
    );
  }

  Map<String, dynamic> toMap() {
    final String typeString = type == CategoryType.income ? 'income' : 'expense';

    final Map<String, dynamic> map = {
      'name': name,
      'type': typeString,
      'user_id': userId,
    };

    if (icon != null) map['icon'] = icon!;
    if (color != null) map['color'] = color!;
    if (id != null) map['id'] = id!;

    return map;
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    CategoryType? type,
    String? userId,
    DateTime? createdAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isIncomeCategory => type == CategoryType.income;
  bool get isExpenseCategory => type == CategoryType.expense;

  @override
  String toString() {
    return 'CategoryModel(id: $id, name: $name, type: $type)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CategoryModel &&
        other.id == id &&
        other.name == name &&
        other.icon == icon &&
        other.color == color &&
        other.type == type &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        icon.hashCode ^
        color.hashCode ^
        type.hashCode ^
        userId.hashCode;
  }
}