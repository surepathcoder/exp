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
  final int? walletFromId;
  final int? walletToId;
  final String? project;
  final int? projectId;

  const Transfer({
    this.id,
    required this.amountFrom,
    required this.currencyFrom,
    required this.amountTo,
    required this.currencyTo,
    required this.date,
    this.note,
    this.userId,
    this.walletFromId,
    this.walletToId,
    this.project,
    this.projectId,
  });

  factory Transfer.fromJson(Map<String, dynamic> json) {
    return Transfer(
      id: json['id'],
      amountFrom: _parseAmount(json['amount_from']),
      currencyFrom: json['currency_from'],
      amountTo: _parseAmount(json['amount_to']),
      currencyTo: json['currency_to'],
      date: DateTime.parse(json['date']),
      note: json['note'],
      userId: json['user_id'],
      walletFromId: json['wallet_from_id'],
      walletToId: json['wallet_to_id'],
      project: json['project'],
      projectId: json['project_id'],
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
      if (walletFromId != null) 'wallet_from_id': walletFromId,
      if (walletToId != null) 'wallet_to_id': walletToId,
      'project': project,
      'project_id': projectId,
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
    int? walletFromId,
    int? walletToId,
    String? project,
    int? projectId,
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
      walletFromId: walletFromId ?? this.walletFromId,
      walletToId: walletToId ?? this.walletToId,
      project: project ?? this.project,
      projectId: projectId ?? this.projectId,
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
        walletFromId,
        walletToId,
        project,
        projectId,
      ];
}

double _parseAmount(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0.0;
  return 0.0;
}
