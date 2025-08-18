import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AlphaVantageService {
  static const String _baseUrl = 'https://www.alphavantage.co/query';
  static String get _apiKey => dotenv.env['ALPHA_VANTAGE_API_KEY'] ?? '';
  
  static final Map<String, DateTime> _lastRequestTime = {};
  static const Duration _minRequestInterval = Duration(seconds: 12); // Free plan: 5 requests/minute

  static Future<bool> _canMakeRequest(String symbol) async {
    final lastTime = _lastRequestTime[symbol];
    if (lastTime != null) {
      final timeDiff = DateTime.now().difference(lastTime);
      if (timeDiff < _minRequestInterval) {
        print('⏳ Rate limit: Waiting ${_minRequestInterval.inSeconds - timeDiff.inSeconds}s for $symbol');
        await Future.delayed(_minRequestInterval - timeDiff);
      }
    }
    _lastRequestTime[symbol] = DateTime.now();
    return true;
  }
  
  static Future<Map<String, dynamic>?> getStockQuote(String symbol) async {
    if (_apiKey.isEmpty) {
      print('❌ Alpha Vantage API key not found in .env file');
      return null;
    }
    
    await _canMakeRequest(symbol);
    
    final url = '$_baseUrl?function=GLOBAL_QUOTE&symbol=$symbol&apikey=$_apiKey';
    
    try {
      print('📡 Getting stock quote for: $symbol');
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data.containsKey('Global Quote')) {
          final quote = data['Global Quote'];
          return {
            'symbol': quote['01. symbol'] ?? symbol,
            'price': double.parse(quote['05. price'] ?? '0'),
            'change': double.parse(quote['09. change'] ?? '0'),
            'changePercent': quote['10. change percent']?.replaceAll('%', '') ?? '0',
            'volume': int.parse(quote['06. volume'] ?? '0'),
            'lastUpdated': DateTime.now(),
          };
        } else if (data.containsKey('Note')) {
          print('⚠️ API Rate limit hit: ${data['Note']}');
          return null;
        }
      }
    } catch (e) {
      print('❌ Error fetching stock quote: $e');
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> getPopularStocks() async {
    final popularStocks = ['AAPL', 'GOOGL', 'MSFT', 'TSLA', 'AMZN', 'META', 'NVDA'];
    List<Map<String, dynamic>> results = [];
    
    for (String symbol in popularStocks) {
      final quote = await getStockQuote(symbol);
      if (quote != null) {
        results.add({
          'symbol': symbol,
          'name': getStockName(symbol),
          'type': 'stock',
          'current_price': quote['price'],
          'previous_price': quote['price'] - quote['change'],
          'change_percent': double.parse(quote['changePercent'].toString()),
        });
      }
      await Future.delayed(Duration(seconds: 1));
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

  static Future<Map<String, dynamic>?> getForexRate(String fromSymbol, String toSymbol) async {
    if (_apiKey.isEmpty) {
      print('❌ Alpha Vantage API key not found in .env file');
      return null;
    }
    
    await _canMakeRequest('$fromSymbol$toSymbol');
    
    final url = '$_baseUrl?function=CURRENCY_EXCHANGE_RATE&from_currency=$fromSymbol&to_currency=$toSymbol&apikey=$_apiKey';
    
    try {
      print('📡 Getting forex rate: $fromSymbol -> $toSymbol');
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data.containsKey('Realtime Currency Exchange Rate')) {
          final rate = data['Realtime Currency Exchange Rate'];
          return {
            'from_currency': rate['1. From_Currency Code'],
            'to_currency': rate['3. To_Currency Code'],
            'rate': double.parse(rate['5. Exchange Rate']),
            'last_updated': DateTime.parse(rate['6. Last Refreshed']),
          };
        }
      }
    } catch (e) {
      print('❌ Error fetching forex rate: $e');
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> getPopularForexRates() async {
    final currencies = ['USD', 'EUR', 'GBP', 'CHF', 'JPY'];
    List<Map<String, dynamic>> results = [];
    
    for (String currency in currencies) {
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
      await Future.delayed(Duration(seconds: 1));
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
    if (_apiKey.isEmpty) {
      print('❌ Alpha Vantage API key not found in .env file');
      return null;
    }
    
    await _canMakeRequest(symbol);
    
    final url = '$_baseUrl?function=CURRENCY_EXCHANGE_RATE&from_currency=$symbol&to_currency=USD&apikey=$_apiKey';
    
    try {
      print('📡 Getting crypto quote for: $symbol');
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data.containsKey('Realtime Currency Exchange Rate')) {
          final rate = data['Realtime Currency Exchange Rate'];
          final usdPrice = double.parse(rate['5. Exchange Rate']);
          
          final tryPrice = usdPrice * 33.5; 
          
          return {
            'symbol': symbol,
            'price_usd': usdPrice,
            'price_try': tryPrice,
            'last_updated': DateTime.parse(rate['6. Last Refreshed']),
          };
        }
      }
    } catch (e) {
      print('❌ Error fetching crypto quote: $e');
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> getPopularCryptos() async {
    final cryptos = ['BTC', 'ETH', 'ADA', 'DOT', 'LINK'];
    List<Map<String, dynamic>> results = [];
    
    for (String crypto in cryptos) {
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
      await Future.delayed(Duration(seconds: 1));
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
    if (_apiKey.isEmpty) {
      print('❌ Alpha Vantage API key not found in .env file');
      return [];
    }
    
    await _canMakeRequest('search_$query');
    
    final url = '$_baseUrl?function=SYMBOL_SEARCH&keywords=$query&apikey=$_apiKey';
    
    try {
      print('🔍 Searching symbols for: $query');
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data.containsKey('bestMatches')) {
          final matches = data['bestMatches'] as List;
          return matches.map((match) => {
            'symbol': match['1. symbol'],
            'name': match['2. name'],
            'type': match['3. type'],
            'region': match['4. region'],
            'currency': match['8. currency'],
          }).toList();
        }
      }
    } catch (e) {
      print('❌ Error searching symbols: $e');
    }
    return [];
  }
  
  static Future<List<Map<String, dynamic>>> getDailyData(String symbol, {int days = 30}) async {
    if (_apiKey.isEmpty) {
      print('❌ Alpha Vantage API key not found in .env file');
      return [];
    }
    
    await _canMakeRequest('daily_$symbol');
    
    final url = '$_baseUrl?function=TIME_SERIES_DAILY&symbol=$symbol&apikey=$_apiKey';
    
    try {
      print('📈 Getting daily data for: $symbol');
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data.containsKey('Time Series (Daily)')) {
          final timeSeries = data['Time Series (Daily)'] as Map<String, dynamic>;
          List<Map<String, dynamic>> dailyData = [];
          
          int count = 0;
          for (String date in timeSeries.keys) {
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
          
          return dailyData.reversed.toList(); // Eski tarihten yeniye sırala
        }
      }
    } catch (e) {
      print('❌ Error fetching daily data: $e');
    }
    return [];
  }
}