import 'package:equatable/equatable.dart';

class Uom extends Equatable {
  final String id;
  final String name;
  final String symbol;

  const Uom({required this.id, required this.name, required this.symbol});

  factory Uom.fromJson(Map<String, dynamic> json) {
    return Uom(id: json['id'], name: json['name'], symbol: json['symbol']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'symbol': symbol};
  }

  @override
  List<Object?> get props => [id, name, symbol];
}
