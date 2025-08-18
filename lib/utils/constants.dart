class AppConstants {
  static const String appName = 'Finolytica';
  static const String appVersion = '1.0.0';

  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;

  static const double smallRadius = 8.0;
  static const double defaultRadius = 12.0;
  static const double largeRadius = 16.0;

  static const Duration shortDuration = Duration(milliseconds: 200);
  static const Duration mediumDuration = Duration(milliseconds: 300);
  static const Duration longDuration = Duration(milliseconds: 500);

  static const String incomeType = 'income';
  static const String expenseType = 'expense';

  static const List<Map<String, dynamic>> defaultCategories = [

    {'name': 'Gıda & İçecek', 'icon': '🍕', 'color': '4294936283', 'type': 'expense'},
    {'name': 'Ulaşım', 'icon': '🚗', 'color': '4283354564', 'type': 'expense'},
    {'name': 'Kira', 'icon': '🏠', 'color': '4281558481', 'type': 'expense'},
    {'name': 'Eğlence', 'icon': '🎬', 'color': '4284481716', 'type': 'expense'},
    {'name': 'Sağlık', 'icon': '💊', 'color': '4293256814', 'type': 'expense'},
    {'name': 'Alışveriş', 'icon': '🛍️', 'color': '4292817493', 'type': 'expense'},
    {'name': 'Diğer', 'icon': '📊', 'color': '4282400255', 'type': 'expense'},
    
    {'name': 'Maaş', 'icon': '💰', 'color': '4285479655', 'type': 'income'},
    {'name': 'Freelance', 'icon': '💼', 'color': '4287137790', 'type': 'income'},
    {'name': 'Yatırım Getiri', 'icon': '📈', 'color': '4278241428', 'type': 'income'},
    {'name': 'Diğer', 'icon': '📊', 'color': '4282400255', 'type': 'income'},
  ];

  static const List<Map<String, String>> currencies = [
    {'code': 'TRY', 'name': 'Türk Lirası', 'symbol': '₺'},
    {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
    {'code': 'GBP', 'name': 'British Pound', 'symbol': '£'},
  ];

  static const String emailRequiredError = 'E-mail gerekli';
  static const String emailInvalidError = 'Geçerli bir e-mail giriniz';
  static const String passwordRequiredError = 'Şifre gerekli';
  static const String passwordMinLengthError = 'Şifre en az 6 karakter olmalı';
  static const String nameRequiredError = 'Ad soyad gerekli';
  static const String amountRequiredError = 'Tutar gerekli';
  static const String amountInvalidError = 'Geçerli bir tutar giriniz';
  static const String titleRequiredError = 'Başlık gerekli';

  static const String loginSuccessMessage = 'Giriş başarılı';
  static const String registerSuccessMessage = 'Hesap oluşturuldu';
  static const String transactionAddedMessage = 'İşlem eklendi';
  static const String transactionUpdatedMessage = 'İşlem güncellendi';
  static const String transactionDeletedMessage = 'İşlem silindi';

  static const String defaultCurrency = 'TRY';
  static const int transactionPageSize = 20;
  static const int recentTransactionsLimit = 10;

  static int getColorValue(String colorString) {
    return int.tryParse(colorString) ?? 4282400255; 
  }

  static List<Map<String, dynamic>> getCategoriesByType(String type) {
    return defaultCategories.where((category) => category['type'] == type).toList();
  }

  static List<Map<String, dynamic>> get incomeCategories =>
      getCategoriesByType(incomeType);

  static List<Map<String, dynamic>> get expenseCategories =>
      getCategoriesByType(expenseType);
}