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
}
