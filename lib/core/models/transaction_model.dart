class TransactionModel {
  final int? id;          // null before saved to DB, set after
  final String merchant;  // who you paid — "Swiggy", "Uber"
  final double amount;    // how much — 450.0
  final String category;  // "Food", "Transport" etc
  final String type;      // "debit" or "credit"
  final DateTime date;    // when it happened
  final String source;    // "sms", "manual", or "csv"
  final String? rawSms;   // original SMS text, kept for reference
  final String? account;  // bank account if known
  final String? upiRef;   // UPI reference number for dedup

  TransactionModel({
    this.id,
    required this.merchant,
    required this.amount,
    required this.category,
    required this.type,
    required this.date,
    required this.source,
    this.rawSms,
    this.account,
    this.upiRef,
  });

  // Convert object → Map for saving to database
  Map<String, dynamic> toMap() => {
        'id': id,
        'merchant': merchant,
        'amount': amount,
        'category': category,
        'type': type,
        'date': date.toIso8601String(),
        'source': source,
        'raw_sms': rawSms,
        'account': account,
        'upi_ref': upiRef,
      };

  // Convert Map from database → object
  factory TransactionModel.fromMap(Map<String, dynamic> map) =>
      TransactionModel(
        id: map['id'],
        merchant: map['merchant'] ?? 'Unknown',
        amount: (map['amount'] as num).toDouble(),
        category: map['category'] ?? 'Other',
        type: map['type'] ?? 'debit',
        date: DateTime.parse(map['date']),
        source: map['source'] ?? 'manual',
        rawSms: map['raw_sms'],
        account: map['account'],
        upiRef: map['upi_ref'],
      );

  TransactionModel copyWith({
    int? id,
    String? merchant,
    double? amount,
    String? category,
    String? type,
    DateTime? date,
    String? source,
    String? rawSms,
    String? account,
    String? upiRef,
  }) =>
      TransactionModel(
        id: id ?? this.id,
        merchant: merchant ?? this.merchant,
        amount: amount ?? this.amount,
        category: category ?? this.category,
        type: type ?? this.type,
        date: date ?? this.date,
        source: source ?? this.source,
        rawSms: rawSms ?? this.rawSms,
        account: account ?? this.account,
        upiRef: upiRef ?? this.upiRef,
      );
}