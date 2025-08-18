class InvestmentModel {
  final String? id;
  final String userId;
  final String symbol;
  final String name;
  final String type; // 'stock', 'crypto', 'gold', 'forex'
  final double amount;
  final double purchasePrice;
  final double? currentPrice;
  final DateTime purchaseDate;
  final DateTime createdAt;

  InvestmentModel({
    this.id,
    required this.userId,
    required this.symbol,
    required this.name,
    required this.type,
    required this.amount,
    required this.purchasePrice,
    this.currentPrice,
    required this.purchaseDate,
    required this.createdAt,
  });

  double get profitLoss {
    if (currentPrice == null) return 0.0;
    return (currentPrice! - purchasePrice) * amount;
  }

  double get percentageChange {
    if (currentPrice == null) return 0.0;
    return ((currentPrice! - purchasePrice) / purchasePrice) * 100;
  }

  double get totalValue {
    return (currentPrice ?? purchasePrice) * amount;
  }

  bool get isProfit => profitLoss > 0;

  factory InvestmentModel.fromMap(Map<String, dynamic> map) {
    return InvestmentModel(
      id: map['id'],
      userId: map['user_id'] ?? '',
      symbol: map['symbol'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? 'stock',
      amount: (map['amount'] ?? 0.0).toDouble(),
      purchasePrice: (map['purchase_price'] ?? 0.0).toDouble(),
      currentPrice: map['current_price'] != null 
          ? (map['current_price'] as num).toDouble() 
          : null,
      purchaseDate: DateTime.parse(map['purchase_date']),
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'symbol': symbol,
      'name': name,
      'type': type,
      'amount': amount,
      'purchase_price': purchasePrice,
      'current_price': currentPrice,
      'purchase_date': purchaseDate.toIso8601String().split('T').first,
    };
  }

  InvestmentModel copyWith({
    String? id,
    String? userId,
    String? symbol,
    String? name,
    String? type,
    double? amount,
    double? purchasePrice,
    double? currentPrice,
    DateTime? purchaseDate,
    DateTime? createdAt,
  }) {
    return InvestmentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      currentPrice: currentPrice ?? this.currentPrice,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'InvestmentModel(id: $id, symbol: $symbol, name: $name, type: $type)';
  }
}