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
  final String? photoUrl;
  final int? userId;

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
    this.project = 'Operations',
    this.photoUrl,
    this.userId,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      amount: json['amount'].toDouble(),
      currency: json['currency'],
      category: json['category'],
      date: DateTime.parse(json['date']),
      note: json['note'],
      isSelfReceipt: json['is_self_receipt'] ?? false,
      paymentMethod: json['payment_method'],
      location: json['location'],
      vendor: json['vendor'],
      project: json['project'] ?? 'Operations',
      photoUrl: json['photo_url'],
      userId: json['user_id'],
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
      'project': project ?? 'Operations',
      'photo_url': photoUrl,
      if (userId != null) 'user_id': userId,
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
    String? photoUrl,
    int? userId,
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
      photoUrl: photoUrl ?? this.photoUrl,
      userId: userId ?? this.userId,
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
        photoUrl,
        userId,
      ];
}
