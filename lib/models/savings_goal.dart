class SavingsGoal {
  final String? id;
  final String userId;
  final String title;
  final String? description;
  final double targetAmount;
  final double currentAmount;
  final DateTime? targetDate;
  final String category;
  final String color;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? completedAt;

  SavingsGoal({
    this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.targetAmount,
    this.currentAmount = 0.0,
    this.targetDate,
    this.category = 'general',
    this.color = '4285479655',
    this.isCompleted = false,
    required this.createdAt,
    this.completedAt,
  });

  double get progressPercentage {
    if (targetAmount == 0) return 0;
    return (currentAmount / targetAmount * 100).clamp(0, 100);
  }

  double get remainingAmount {
    return (targetAmount - currentAmount).clamp(0, double.infinity);
  }

  double? get dailyTarget {
    if (targetDate == null) return null;
    final daysLeft = targetDate!.difference(DateTime.now()).inDays;
    if (daysLeft <= 0) return null;
    return remainingAmount / daysLeft;
  }

  String get categoryIcon {
    switch (category) {
      case 'emergency':
        return '🚨';
      case 'vacation':
        return '🏖️';
      case 'house':
        return '🏠';
      case 'car':
        return '🚗';
      case 'education':
        return '📚';
      case 'wedding':
        return '💍';
      default:
        return '💰';
    }
  }

  String get categoryName {
    switch (category) {
      case 'emergency':
        return 'Acil Durum';
      case 'vacation':
        return 'Tatil';
      case 'house':
        return 'Ev';
      case 'car':
        return 'Araba';
      case 'education':
        return 'Eğitim';
      case 'wedding':
        return 'Düğün';
      default:
        return 'Genel';
    }
  }

  factory SavingsGoal.fromMap(Map<String, dynamic> map) {
    return SavingsGoal(
      id: map['id'],
      userId: map['user_id'],
      title: map['title'] ?? '',
      description: map['description'],
      targetAmount: double.parse(map['target_amount'].toString()),
      currentAmount: double.parse(map['current_amount']?.toString() ?? '0'),
      targetDate: map['target_date'] != null ? DateTime.parse(map['target_date']) : null,
      category: map['category'] ?? 'general',
      color: map['color'] ?? '4285479655',
      isCompleted: map['is_completed'] ?? false,
      createdAt: DateTime.parse(map['created_at']),
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'title': title,
      'description': description,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'target_date': targetDate?.toIso8601String().split('T')[0],
      'category': category,
      'color': color,
      'is_completed': isCompleted,
    };
  }

  SavingsGoal copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    double? targetAmount,
    double? currentAmount,
    DateTime? targetDate,
    String? category,
    String? color,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return SavingsGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      targetDate: targetDate ?? this.targetDate,
      category: category ?? this.category,
      color: color ?? this.color,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}