import 'category.dart';

class TransactionModel {
  final String? id;
  final String userId;
  final String? categoryId;
  final String title;
  final double amount;
  final String type; // 'income' veya 'expense'
  final String? description;
  final DateTime date;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final CategoryModel? category; // İlişkili kategori

  TransactionModel({
    this.id,
    required this.userId,
    this.categoryId,
    required this.title,
    required this.amount,
    required this.type,
    this.description,
    required this.date,
    required this.createdAt,
    this.updatedAt,
    this.category,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic dateValue) {
      try {
        if (dateValue == null) return DateTime.now();
        if (dateValue is DateTime) return dateValue;
        return DateTime.parse(dateValue.toString());
      } catch (e) {
        print('Date parse error: $e, value: $dateValue');
        return DateTime.now();
      }
    }

    return TransactionModel(
      id: map['id']?.toString(),
      userId: map['user_id']?.toString() ?? '',
      categoryId: map['category_id']?.toString(),
      title: map['title']?.toString() ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      type: map['type']?.toString() ?? 'expense',
      description: map['description']?.toString(),
      date: parseDate(map['date']),
      createdAt: parseDate(map['created_at']),
      updatedAt: map['updated_at'] != null ? parseDate(map['updated_at']) : null,
      category: map['categories'] != null 
          ? CategoryModel.fromMap(Map<String, dynamic>.from(map['categories']))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'user_id': userId,
      'title': title,
      'amount': amount,
      'type': type,
      'date': date.toIso8601String().split('T').first,
    };

    if (categoryId != null) map['category_id'] = categoryId;
    if (description != null && description!.isNotEmpty) {
      map['description'] = description;
    }
    if (id != null) map['id'] = id;

    return map;
  }

  TransactionModel copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? title,
    double? amount,
    String? type,
    String? description,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    CategoryModel? category,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      description: description ?? this.description,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
    );
  }

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';

  @override
  String toString() {
    return 'TransactionModel(id: $id, title: $title, amount: $amount, type: $type)';
  }
}