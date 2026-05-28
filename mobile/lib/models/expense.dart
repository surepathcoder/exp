import 'package:equatable/equatable.dart';

class Expense extends Equatable {
  final int? id;
  final double amount;
  final String currency;
  final String category;
  final DateTime date;
  final String? note;
  final bool isSelfReceipt;
  final String? paymentMethod;
  final String? location;
  final String? vendor;
  final String? project;
  final int? projectId;
  final String? photoUrl;
  final int? userId;
  final int? walletId;

  const Expense({
    this.id,
    required this.amount,
    required this.currency,
    required this.category,
    required this.date,
    this.note,
    this.isSelfReceipt = false,
    this.paymentMethod,
    this.location,
    this.vendor,
    this.project,
    this.projectId,
    this.photoUrl,
    this.userId,
    this.walletId,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      amount: _parseAmount(json['amount']),
      currency: json['currency'],
      category: json['category'],
      date: DateTime.parse(json['date']),
      note: json['note'],
      isSelfReceipt: json['is_self_receipt'] ?? false,
      paymentMethod: json['payment_method'],
      location: json['location'],
      vendor: json['vendor'],
      project: json['project'],
      projectId: json['project_id'],
      photoUrl: json['photo_url'],
      userId: json['user_id'],
      walletId: json['wallet_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'amount': amount,
      'currency': currency,
      'category': category,
      'date': date.toIso8601String(),
      'note': note,
      'is_self_receipt': isSelfReceipt,
      'payment_method': paymentMethod,
      'location': location,
      'vendor': vendor,
      'project': project,
      'project_id': projectId,
      'photo_url': photoUrl,
      if (userId != null) 'user_id': userId,
      if (walletId != null) 'wallet_id': walletId,
    };
  }

  Expense copyWith({
    int? id,
    double? amount,
    String? currency,
    String? category,
    DateTime? date,
    String? note,
    bool? isSelfReceipt,
    String? paymentMethod,
    String? location,
    String? vendor,
    String? project,
    int? projectId,
    String? photoUrl,
    int? userId,
    int? walletId,
  }) {
    return Expense(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      category: category ?? this.category,
      date: date ?? this.date,
      note: note ?? this.note,
      isSelfReceipt: isSelfReceipt ?? this.isSelfReceipt,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      location: location ?? this.location,
      vendor: vendor ?? this.vendor,
      project: project ?? this.project,
      projectId: projectId ?? this.projectId,
      photoUrl: photoUrl ?? this.photoUrl,
      userId: userId ?? this.userId,
      walletId: walletId ?? this.walletId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        amount,
        currency,
        category,
        date,
        note,
        isSelfReceipt,
        paymentMethod,
        location,
        vendor,
        project,
        projectId,
        photoUrl,
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
