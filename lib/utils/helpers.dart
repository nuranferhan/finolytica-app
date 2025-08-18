import 'package:intl/intl.dart';

class Helpers {
  static String formatCurrency(double amount, {String currency = 'TRY'}) {
    final formatter = NumberFormat.currency(
      symbol: currency == 'TRY' ? '₺' : currency,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd.MM.yyyy').format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('dd MMM').format(date);
  }

  static bool isThisMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  static bool isThisYear(DateTime date) {
    return date.year == DateTime.now().year;
  }

  static int hexToInt(String hex) {
    return int.parse(hex.replaceAll('#', '0xFF'));
  }

  static double? parseDouble(String value) {
    try {
      return double.parse(value.replaceAll(',', '.'));
    } catch (e) {
      return null;
    }
  }

  static bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
