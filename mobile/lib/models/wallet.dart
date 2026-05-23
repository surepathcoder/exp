class Wallet {
  final int id;
  final String name;
  final String type; // cash, bank, mobile_money, credit_card
  final String currency;
  final double openingBalance;
  final double balance;
  final String icon;
  final String color;
  final bool isActive;
  final int userId;
  final DateTime createdAt;

  Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    required this.openingBalance,
    required this.balance,
    required this.icon,
    required this.color,
    required this.isActive,
    required this.userId,
    required this.createdAt,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as int,
      name: json['name'] as String,
      type: json['type'] as String,
      currency: json['currency'] as String,
      openingBalance: _parseAmount(json['opening_balance']),
      balance: _parseAmount(json['balance']),
      icon: json['icon'] as String? ?? 'wallet',
      color: json['color'] as String? ?? '#3D1B5B',
      isActive: json['is_active'] as bool? ?? true,
      userId: json['user_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'currency': currency,
      'opening_balance': openingBalance,
      'balance': balance,
      'icon': icon,
      'color': color,
      'is_active': isActive,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

double _parseAmount(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0.0;
  return 0.0;
}
