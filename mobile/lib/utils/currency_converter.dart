import 'package:dio/dio.dart';

class CurrencyConverter {
  // Conversion rates to USD as specified (default fallbacks)
  static Map<String, double> ratesToUsd = {
    'USD': 1.0,
    'TZS': 2500.0,
    'KES': 130.0,
  };

  static void updateRates(Map<String, double> newRates) {
    newRates.forEach((key, value) {
      if (ratesToUsd.containsKey(key)) {
        ratesToUsd[key] = value;
      }
    });
  }

  static double convertToUsd(double amount, String currency) {
    if (currency == 'USD') return amount;
    final rate = ratesToUsd[currency];
    if (rate == null || rate == 0) return amount; // Fallback
    return amount / rate;
  }

  // Fetch live rates directly from external API as fallback
  static Future<void> fetchFallbackRates() async {
    try {
      final dio = Dio();
      final response = await dio.get('https://open.er-api.com/v6/latest/USD');
      if (response.statusCode == 200 && response.data != null) {
        final rates = response.data['rates'] as Map<String, dynamic>?;
        if (rates != null) {
          final tzs = rates['TZS']?.toDouble();
          final kes = rates['KES']?.toDouble();
          if (tzs != null) ratesToUsd['TZS'] = tzs;
          if (kes != null) ratesToUsd['KES'] = kes;
        }
      }
    } catch (e) {
      // Fail silently and keep using existing rates
    }
  }
}
