class CurrencyConverter {
  // Conversion rates to USD as specified
  static const Map<String, double> _ratesToUsd = {
    'USD': 1.0,
    'CDF': 2800.0,
    'TZS': 2500.0,
    'UGX': 3700.0,
  };

  static double convertToUsd(double amount, String currency) {
    if (currency == 'USD') return amount;
    final rate = _ratesToUsd[currency];
    if (rate == null || rate == 0) return amount; // Fallback
    return amount / rate;
  }
}
