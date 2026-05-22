class Constants {
  // Use http://127.0.0.1:8000/api for local dev with adb reverse, or the provided env variable
  static const String baseUrl = String.fromEnvironment('API_URL', defaultValue: 'http://127.0.0.1:8000/api');
  
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String favoriteFiltersKey = 'favorite_filters';

  static const List<String> categories = [
    "Travel", "Worship committee", "Volunteers committee", "Technical committee",
    "Protocol committee", "Invasion", "Zones", "BOA,ECC,APM", "Youth committee",
    "Woman committee", "Prayer committee", "Church Mobilization", "Promo",
    "Food & Drinks", "Accommodation", "Transfer", "Hospitality", "Permits",
    "Appreciation", "Internet/Phone", "Print", "Committees", "Other"
  ];

  static const List<String> currencies = ['USD', 'TZS', 'KES'];
  static const List<String> paymentMethods = ['Cash', 'Bank', 'Mobile Money'];
}
