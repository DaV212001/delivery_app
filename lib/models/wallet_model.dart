class WalletBalance {
  final double amount;

  const WalletBalance({required this.amount});

  factory WalletBalance.fromJson(dynamic json) {
    if (json == null) return const WalletBalance(amount: 0.0);
    if (json is num) return WalletBalance(amount: json.toDouble());
    if (json is String) {
      return WalletBalance(amount: double.tryParse(json) ?? 0.0);
    }
    if (json is Map) {
      final raw = json['amount'] ?? json['wallet_amount'] ?? json['data'];
      return WalletBalance(amount: double.tryParse(raw?.toString() ?? '0') ?? 0.0);
    }
    return const WalletBalance(amount: 0.0);
  }

  String get formattedBirr => '${amount.toStringAsFixed(2)} Br';
}

class WalletTransaction {
  final int? id;
  final double amount;
  final String? type; // 'credit', 'debit', 'topup', 'bonus'
  final String title;
  final String? description;
  final String? paymentStatus; // '0', '1', 'completed', 'pending'
  final DateTime? date;
  final String? rawDate;

  const WalletTransaction({
    this.id,
    required this.amount,
    this.type,
    required this.title,
    this.description,
    this.paymentStatus,
    this.date,
    this.rawDate,
  });

  bool get isCompleted =>
      paymentStatus == '1' ||
      paymentStatus == 'completed' ||
      paymentStatus == 'success';

  bool get isPending => !isCompleted;

  bool get isBonus =>
      type == 'bonus' || title.toLowerCase().contains('bonus');

  bool get isTopup =>
      type == 'topup' ||
      title.toLowerCase().contains('topup') ||
      title.toLowerCase().contains('top up');

  bool get isDebit =>
      type == 'debit' || amount.isNegative;

  String get formattedAmount {
    final prefix = isDebit ? '-' : '+';
    final absAmount = amount.abs();
    return '$prefix${absAmount.toStringAsFixed(2)} Br';
  }

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    final rawTitle = json['title'] ??
        json['description'] ??
        json['reason'] ??
        'Wallet Transaction';
    final titleStr = rawTitle.toString();

    final rawAmount = double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0;
    final status = json['payment_status']?.toString() ??
        json['status']?.toString() ??
        '1';
    final dateStr = json['date']?.toString() ?? json['created_at']?.toString();
    final parsedDate = dateStr != null ? DateTime.tryParse(dateStr) : null;

    String detectedType = json['type']?.toString() ?? '';
    if (detectedType.isEmpty) {
      final t = titleStr.toLowerCase();
      if (t.contains('bonus')) {
        detectedType = 'bonus';
      } else if (t.contains('topup') || t.contains('top-up') || t.contains('top up')) {
        detectedType = 'topup';
      } else if (rawAmount < 0 || t.contains('order') || t.contains('debit')) {
        detectedType = 'debit';
      } else {
        detectedType = 'credit';
      }
    }

    return WalletTransaction(
      id: json['id'] is int
          ? json['id']
          : int.tryParse(json['id']?.toString() ?? ''),
      amount: rawAmount,
      type: detectedType,
      title: titleStr,
      description: json['description']?.toString() ?? titleStr,
      paymentStatus: status,
      date: parsedDate,
      rawDate: dateStr,
    );
  }
}
