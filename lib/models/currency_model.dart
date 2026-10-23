class CurrencyModel {
  final int id;
  final String code;
  final String symbol;
  final String? name;

  const CurrencyModel({
    required this.id,
    required this.code,
    required this.symbol,
    this.name,
  });

  factory CurrencyModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final parsedId = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '0') ?? 0;

    return CurrencyModel(
      id: parsedId,
      code: json['code']?.toString() ?? json['currency_code']?.toString() ?? '',
      symbol: json['symbol']?.toString() ?? json['currency_symbol']?.toString() ?? '',
      name: json['name']?.toString() ?? json['currency_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'symbol': symbol,
    if (name != null) 'name': name,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurrencyModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => '$code ($symbol)';
}
