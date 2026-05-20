import 'package:equatable/equatable.dart';

class Income extends Equatable {
  final int? id;
  final double amount;
  final String currency;
  final String source;
  final DateTime date;
  final String? note;
  final int? userId;

  const Income({
    this.id,
    required this.amount,
    required this.currency,
    required this.source,
    required this.date,
    this.note,
    this.userId,
  });

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['id'],
      amount: json['amount'].toDouble(),
      currency: json['currency'],
      source: json['source'],
      date: DateTime.parse(json['date']),
      note: json['note'],
      userId: json['user_id'],
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
  }) {
    return Income(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      source: source ?? this.source,
      date: date ?? this.date,
      note: note ?? this.note,
      userId: userId ?? this.userId,
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
      ];
}
