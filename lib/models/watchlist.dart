class WatchlistItem {
  final String? id;
  final String userId;
  final String symbol;
  final String name;
  final String type;
  final double? currentPrice;
  final double? previousPrice;
  final DateTime lastUpdated;
  final DateTime createdAt;

  WatchlistItem({
    this.id,
    required this.userId,
    required this.symbol,
    required this.name,
    this.type = 'forex',
    this.currentPrice,
    this.previousPrice,
    required this.lastUpdated,
    required this.createdAt,
  });

  double get changePercentage {
    if (previousPrice == null || currentPrice == null || previousPrice == 0) {
      return 0;
    }
    return ((currentPrice! - previousPrice!) / previousPrice!) * 100;
  }

  double get changeAmount {
    if (previousPrice == null || currentPrice == null) return 0;
    return currentPrice! - previousPrice!;
  }

  String get changeStatus {
    final change = changePercentage;
    if (change > 0) return 'positive';
    if (change < 0) return 'negative';
    return 'neutral';
  }

String get symbolIcon {
  switch (type) {
    case 'forex':
      return _getForexIcon(symbol);
    case 'crypto':
      return _getCryptoIcon(symbol);
    case 'stock':
      return _getStockIcon(symbol);
    default:
      return '💱';
  }
}

String _getForexIcon(String symbol) {
  switch (symbol.toUpperCase()) {
    case 'USD':
      return '🇺🇸';
    case 'EUR':
      return '🇪🇺';
    case 'GBP':
      return '🇬🇧';
    case 'CHF':
      return '🇨🇭';
    case 'JPY':
      return '🇯🇵';
    case 'CAD':
      return '🇨🇦';
    case 'AUD':
      return '🇦🇺';
    case 'CNY':
      return '🇨🇳';
    case 'RUB':
      return '🇷🇺';
    default:
      return '💱';
  }
}


String _getCryptoIcon(String symbol) {
  switch (symbol.toUpperCase()) {
    case 'BTC':
      return '₿';
    case 'ETH':
      return 'Ξ';
    case 'ADA':
      return '₳';
    case 'DOT':
      return '●';
    case 'LINK':
      return '🔗';
    case 'XRP':
      return '◎';
    case 'LTC':
      return 'Ł';
    case 'BCH':
      return '₿';
    default:
      return '🪙';
  }
}

String _getStockIcon(String symbol) {
  switch (symbol.toUpperCase()) {
    case 'AAPL':
      return '🍎';
    case 'GOOGL':
    case 'GOOG':
      return '🔍';
    case 'MSFT':
      return '🪟';
    case 'TSLA':
      return '🚗';
    case 'AMZN':
      return '📦';
    case 'META':
      return '👥';
    case 'NVDA':
      return '🎮';
    default:
      return '📈';
  }
}

  String get formattedPrice {
    if (currentPrice == null) return 'N/A';
    if (type == 'forex') {
      return '₺${currentPrice!.toStringAsFixed(4)}';
    }
    return '₺${currentPrice!.toStringAsFixed(2)}';
  }

  factory WatchlistItem.fromMap(Map<String, dynamic> map) {
    return WatchlistItem(
      id: map['id'],
      userId: map['user_id'],
      symbol: map['symbol'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? 'forex',
      currentPrice: map['current_price'] != null 
          ? double.parse(map['current_price'].toString()) 
          : null,
      previousPrice: map['previous_price'] != null 
          ? double.parse(map['previous_price'].toString()) 
          : null,
      lastUpdated: DateTime.parse(map['last_updated']),
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'symbol': symbol,
      'name': name,
      'type': type,
      'current_price': currentPrice,
      'previous_price': previousPrice,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  WatchlistItem copyWith({
    String? id,
    String? userId,
    String? symbol,
    String? name,
    String? type,
    double? currentPrice,
    double? previousPrice,
    DateTime? lastUpdated,
    DateTime? createdAt,
  }) {
    return WatchlistItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      symbol: symbol ?? this.symbol,
      name: name ?? this.name,
      type: type ?? this.type,
      currentPrice: currentPrice ?? this.currentPrice,
      previousPrice: previousPrice ?? this.previousPrice,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}