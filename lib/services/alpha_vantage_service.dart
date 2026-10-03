import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class _CacheEntry {
  final dynamic value;
  final DateTime savedAt;
  _CacheEntry(this.value, this.savedAt);
}

class AlphaVantageService {
  static const String _host = 'www.alphavantage.co';
  static const String _path = '/query';
  static String get _apiKey => dotenv.env['ALPHA_VANTAGE_API_KEY'] ?? '';

  static const int _maxRequestsPerWindow = 5;
  static const Duration _window = Duration(seconds: 60);
  static final List<DateTime> _requestTimes = [];
  static Future<void> _lock = Future.value();

  static Future<void> _waitForSlot() async {
    final previous = _lock;
    final done = Completer<void>();
    _lock = done.future;
    try {
      await previous;
      while (true) {
        final now = DateTime.now();
        _requestTimes.removeWhere((t) => now.difference(t) >= _window);
        if (_requestTimes.length < _maxRequestsPerWindow) {
          _requestTimes.add(now);
          return;
        }
        final wait = _window - now.difference(_requestTimes.first);
        debugPrint('⏳ Rate limit: ${wait.inSeconds + 1}s bekleniyor');
        await Future.delayed(wait + const Duration(milliseconds: 100));
      }
    } finally {
      done.complete();
    }
  }

  static const Duration _cacheTtl = Duration(minutes: 5);
  static const Duration _dailyCacheTtl = Duration(minutes: 30);
  static final Map<String, _CacheEntry> _cache = {};

  static dynamic _readCache(String key, {Duration ttl = _cacheTtl}) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.savedAt) > ttl) {
      _cache.remove(key);
      return null;
    }
    return entry.value;
  }

  static void _writeCache(String key, dynamic value) {
    _cache[key] = _CacheEntry(value, DateTime.now());
  }

  static void clearCache() => _cache.clear();
  
  static Future<Map<String, dynamic>?> _fetch(Map<String, String> params) async {
    if (_apiKey.isEmpty) {
      debugPrint('❌ Alpha Vantage API key not found in .env file');
      return null;
    }

    await _waitForSlot();

    try {
      final uri = Uri.https(_host, _path, {...params, 'apikey': _apiKey});
      final response =
          await http.get(uri).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        debugPrint('❌ Alpha Vantage HTTP ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body);
      if (data is! Map<String, dynamic>) return null;

      if (data.containsKey('Note') || data.containsKey('Information')) {
        debugPrint('⚠️ API limit/bilgi mesajı: '
            '${data['Note'] ?? data['Information']}');
        return null;
      }
      if (data.containsKey('Error Message')) {
        debugPrint('⚠️ API hata mesajı: ${data['Error Message']}');
        return null;
      }
      return data;
    } catch (e) {
      debugPrint('❌ Alpha Vantage isteği başarısız: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getStockQuote(String symbol) async {
    final cacheKey = 'stock:$symbol';
    final cached = _readCache(cacheKey);
    if (cached != null) return cached as Map<String, dynamic>;

    final data = await _fetch({
      'function': 'GLOBAL_QUOTE',
      'symbol': symbol,
    });
    if (data == null) return null;

    final quote = data['Global Quote'];
    if (quote is Map && quote.isNotEmpty) {
      final result = <String, dynamic>{
        'symbol': quote['01. symbol'] ?? symbol,
        'price': double.tryParse('${quote['05. price'] ?? '0'}') ?? 0.0,
        'change': double.tryParse('${quote['09. change'] ?? '0'}') ?? 0.0,
        'changePercent':
            '${quote['10. change percent'] ?? '0'}'.replaceAll('%', ''),
        'volume': int.tryParse('${quote['06. volume'] ?? '0'}') ?? 0,
        'lastUpdated': DateTime.now(),
      };
      _writeCache(cacheKey, result);
      return result;
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> getPopularStocks() async {
    final popularStocks = [
      'AAPL', 'GOOGL', 'MSFT', 'TSLA', 'AMZN', 'META', 'NVDA'
    ];
    final List<Map<String, dynamic>> results = [];

    for (final symbol in popularStocks) {
      final quote = await getStockQuote(symbol);
      if (quote != null) {
        results.add({
          'symbol': symbol,
          'name': getStockName(symbol),
          'type': 'stock',
          'current_price': quote['price'],
          'previous_price': quote['price'] - quote['change'],
          'change_percent':
              double.tryParse(quote['changePercent'].toString()) ?? 0.0,
        });
      }
    }
    return results;
  }

  static String getStockName(String symbol) {
    const stockNames = {
      'AAPL': 'Apple Inc.',
      'GOOGL': 'Alphabet Inc.',
      'MSFT': 'Microsoft Corporation',
      'TSLA': 'Tesla Inc.',
      'AMZN': 'Amazon.com Inc.',
      'META': 'Meta Platforms Inc.',
      'NVDA': 'NVIDIA Corporation',
    };
    return stockNames[symbol] ?? symbol;
  }

  static Future<Map<String, dynamic>?> getForexRate(
      String fromSymbol, String toSymbol) async {
    final cacheKey = 'fx:$fromSymbol:$toSymbol';
    final cached = _readCache(cacheKey);
    if (cached != null) return cached as Map<String, dynamic>;

    final data = await _fetch({
      'function': 'CURRENCY_EXCHANGE_RATE',
      'from_currency': fromSymbol,
      'to_currency': toSymbol,
    });
    if (data == null) return null;

    final rate = data['Realtime Currency Exchange Rate'];
    if (rate is Map) {
      final value = double.tryParse('${rate['5. Exchange Rate']}');
      if (value == null) return null;

      final result = <String, dynamic>{
        'from_currency': rate['1. From_Currency Code'],
        'to_currency': rate['3. To_Currency Code'],
        'rate': value,
        'last_updated':
            DateTime.tryParse('${rate['6. Last Refreshed']}') ?? DateTime.now(),
      };
      _writeCache(cacheKey, result);
      return result;
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> getPopularForexRates() async {
    final currencies = ['USD', 'EUR', 'GBP', 'CHF', 'JPY'];
    final List<Map<String, dynamic>> results = [];

    for (final currency in currencies) {
      final rate = await getForexRate(currency, 'TRY');
      if (rate != null) {
        results.add({
          'symbol': currency,
          'name': getCurrencyName(currency),
          'type': 'forex',
          'current_price': rate['rate'],
          'last_updated': rate['last_updated'],
        });
      }
    }
    return results;
  }

  static String getCurrencyName(String symbol) {
    const currencyNames = {
      'USD': 'Amerikan Doları',
      'EUR': 'Euro',
      'GBP': 'İngiliz Sterlini',
      'CHF': 'İsviçre Frangı',
      'JPY': 'Japon Yeni',
    };
    return currencyNames[symbol] ?? symbol;
  }

  static Future<Map<String, dynamic>?> getCryptoQuote(String symbol) async {
    final usd = await getForexRate(symbol, 'USD');
    if (usd == null) return null;

    final usdTry = await getForexRate('USD', 'TRY');
    if (usdTry == null) return null;

    final usdPrice = usd['rate'] as double;
    final tryPrice = usdPrice * (usdTry['rate'] as double);

    return {
      'symbol': symbol,
      'price_usd': usdPrice,
      'price_try': tryPrice,
      'last_updated': usd['last_updated'],
    };
  }

  static Future<List<Map<String, dynamic>>> getPopularCryptos() async {
    final cryptos = ['BTC', 'ETH', 'ADA', 'DOT', 'LINK'];
    final List<Map<String, dynamic>> results = [];

    for (final crypto in cryptos) {
      final quote = await getCryptoQuote(crypto);
      if (quote != null) {
        results.add({
          'symbol': crypto,
          'name': getCryptoName(crypto),
          'type': 'crypto',
          'current_price': quote['price_try'],
          'last_updated': quote['last_updated'],
        });
      }
    }
    return results;
  }

  static String getCryptoName(String symbol) {
    const cryptoNames = {
      'BTC': 'Bitcoin',
      'ETH': 'Ethereum',
      'ADA': 'Cardano',
      'DOT': 'Polkadot',
      'LINK': 'Chainlink',
    };
    return cryptoNames[symbol] ?? symbol;
  }

  static Future<List<Map<String, dynamic>>> searchSymbols(String query) async {
    final cacheKey = 'search:${query.toLowerCase()}';
    final cached = _readCache(cacheKey);
    if (cached != null) return List<Map<String, dynamic>>.from(cached);

    final data = await _fetch({
      'function': 'SYMBOL_SEARCH',
      'keywords': query,
    });
    if (data == null) return [];

    final matches = data['bestMatches'];
    if (matches is List) {
      final results = matches
          .map<Map<String, dynamic>>((match) => {
                'symbol': match['1. symbol'],
                'name': match['2. name'],
                'type': match['3. type'],
                'region': match['4. region'],
                'currency': match['8. currency'],
              })
          .toList();
      _writeCache(cacheKey, results);
      return results;
    }
    return [];
  }

  static Future<List<Map<String, dynamic>>> getDailyData(String symbol,
      {int days = 30}) async {
    final cacheKey = 'daily:$symbol:$days';
    final cached = _readCache(cacheKey, ttl: _dailyCacheTtl);
    if (cached != null) return List<Map<String, dynamic>>.from(cached);

    final data = await _fetch({
      'function': 'TIME_SERIES_DAILY',
      'symbol': symbol,
    });
    if (data == null) return [];

    final timeSeries = data['Time Series (Daily)'];
    if (timeSeries is Map<String, dynamic>) {
      final List<Map<String, dynamic>> dailyData = [];

      int count = 0;
      for (final date in timeSeries.keys) {
        if (count >= days) break;

        final dayData = timeSeries[date];
        dailyData.add({
          'date': date,
          'open': double.parse(dayData['1. open']),
          'high': double.parse(dayData['2. high']),
          'low': double.parse(dayData['3. low']),
          'close': double.parse(dayData['4. close']),
          'volume': int.parse(dayData['5. volume']),
        });
        count++;
      }

      final ordered = dailyData.reversed.toList(); // Eskiden yeniye
      _writeCache(cacheKey, ordered);
      return ordered;
    }
    return [];
  }
}
