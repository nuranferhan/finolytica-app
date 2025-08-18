import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static const String appName = 'Finolytica';
  static const String appVersion = '1.0.0';
  
  static String get supabaseUrl => dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get alphaVantageApiKey => dotenv.env['ALPHA_VANTAGE_API_KEY'] ?? '';
  static String get openAiApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  
  static const String alphaVantageBaseUrl = 'https://www.alphavantage.co/query';

  static const int maxRequestsPerMinute = 5; // Free plan limiti
  static const Duration requestDelay = Duration(seconds: 12);
  
  static const String defaultCurrency = 'TRY';
  static const List<String> supportedCurrencies = ['TRY', 'USD', 'EUR', 'GBP'];
  
  static const List<Map<String, dynamic>> defaultCategories = [
    {'name': 'Gıda & İçecek', 'icon': '🍕', 'color': 0xFFFF6B6B, 'type': 'expense'},
    {'name': 'Ulaşım', 'icon': '🚗', 'color': 0xFF4ECDC4, 'type': 'expense'},
    {'name': 'Kira', 'icon': '🏠', 'color': 0xFF45B7D1, 'type': 'expense'},
    {'name': 'Eğlence', 'icon': '🎬', 'color': 0xFF96CEB4, 'type': 'expense'},
    {'name': 'Sağlık', 'icon': '💊', 'color': 0xFFFDCB6E, 'type': 'expense'},
    {'name': 'Maaş', 'icon': '💰', 'color': 0xFF6C5CE7, 'type': 'income'},
    {'name': 'Freelance', 'icon': '💼', 'color': 0xFFA29BFE, 'type': 'income'},
    {'name': 'Diğer', 'icon': '📊', 'color': 0xFF74B9FF, 'type': 'both'},
  ];
}