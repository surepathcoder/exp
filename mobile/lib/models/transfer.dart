import 'package:equatable/equatable.dart';

class Transfer extends Equatable {
  final int? id;
  final double amountFrom;
  final String currencyFrom;
  final double amountTo;
  final String currencyTo;
  final DateTime date;
  final String? note;
  final int? userId;

  const Transfer({
    this.id,
    required this.amountFrom,
    required this.currencyFrom,
    required this.amountTo,
    required this.currencyTo,
    required this.date,
    this.note,
    this.userId,
  });

  factory Transfer.fromJson(Map<String, dynamic> json) {
    return Transfer(
      id: json['id'],
      amountFrom: json['amount_from'].toDouble(),
      currencyFrom: json['currency_from'],
      amountTo: json['amount_to'].toDouble(),
      currencyTo: json['currency_to'],
      date: DateTime.parse(json['date']),
      note: json['note'],
      userId: json['user_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'amount_from': amountFrom,
      'currency_from': currencyFrom,
      'amount_to': amountTo,
      'currency_to': currencyTo,
      'date': date.toIso8601String(),
      'note': note,
      if (userId != null) 'user_id': userId,
    };
  }

  Transfer copyWith({
    int? id,
    double? amountFrom,
    String? currencyFrom,
    double? amountTo,
    String? currencyTo,
    DateTime? date,
    String? note,
    int? userId,
  }) {
    return Transfer(
      id: id ?? this.id,
      amountFrom: amountFrom ?? this.amountFrom,
      currencyFrom: currencyFrom ?? this.currencyFrom,
      amountTo: amountTo ?? this.amountTo,
      currencyTo: currencyTo ?? this.currencyTo,
      date: date ?? this.date,
      note: note ?? this.note,
      userId: userId ?? this.userId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        amountFrom,
        currencyFrom,
        amountTo,
        currencyTo,
        date,
        note,
        userId,
      ];
}
