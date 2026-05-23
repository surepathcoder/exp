import 'package:equatable/equatable.dart';

class Income extends Equatable {
  final int? id;
  final double amount;
  final String currency;
  final String source;
  final DateTime date;
  final String? note;
  final int? userId;
  final int? walletId;

  const Income({
    this.id,
    required this.amount,
    required this.currency,
    required this.source,
    required this.date,
    this.note,
    this.userId,
    this.walletId,
  });

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['id'],
      amount: _parseAmount(json['amount']),
      currency: json['currency'],
      source: json['source'],
      date: DateTime.parse(json['date']),
      note: json['note'],
      userId: json['user_id'],
      walletId: json['wallet_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'currency': currency,
      'source': source,
      'date': date.toIso8601String(),
      'note': note,
      if (userId != null) 'user_id': userId,
      if (walletId != null) 'wallet_id': walletId,
    };
  }

  Income copyWith({
    int? id,
    double? amount,
    String? currency,
    String? source,
    DateTime? date,
    String? note,
    int? userId,
    int? walletId,
  }) {
    return Income(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      source: source ?? this.source,
      date: date ?? this.date,
      note: note ?? this.note,
      userId: userId ?? this.userId,
      walletId: walletId ?? this.walletId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        amount,
        currency,
        source,
        date,
        note,
        userId,
        walletId,
      ];
}

double _parseAmount(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0.0;
  return 0.0;
}
