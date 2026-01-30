class ServiceRate {
  final String id;
  final String name;
  final String symbol;

  const ServiceRate({
    required this.id,
    required this.name,
    required this.symbol,
  });

  factory ServiceRate.fromJson(Map<String, dynamic> json) {
    return ServiceRate(
      id: json['id'],
      name: json['name'],
      symbol: json['symbol'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'symbol': symbol};
  }
}
