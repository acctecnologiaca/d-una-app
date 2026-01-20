import 'package:equatable/equatable.dart';

class Client extends Equatable {
  final String id;
  final String ownerId;
  final String name;
  final String type; // 'company' or 'person'
  final String? taxId;
  final String? email;
  final String? phone;
  final String? address;
  final String? alias;
  final String? city;
  final String? state;
  final String? country;
  final DateTime createdAt;
  final List<Contact> contacts;

  const Client({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.type,
    this.taxId,
    this.alias,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.state,
    this.country,
    required this.createdAt,
    this.contacts = const [],
  });

  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'],
      ownerId: json['owner_id'],
      name: json['name'],
      type: json['type'],
      taxId: json['tax_id'],
      alias: json['alias'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      city: json['city'],
      state: json['state'],
      country: json['country'],
      createdAt: DateTime.parse(json['created_at']),
      contacts:
          (json['contacts'] as List? ?? [])
              .map((c) => Contact.fromJson(c))
              .toList()
            ..sort(
              (a, b) => (b.isPrimary ? 1 : 0).compareTo(a.isPrimary ? 1 : 0),
            ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'owner_id': ownerId,
      'name': name,
      'type': type,
      'tax_id': taxId,
      'alias': alias,
      'email': email,
      'phone': phone,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Client copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? type,
    String? taxId,
    String? alias,
    String? email,
    String? phone,
    String? address,
    String? city,
    String? state,
    String? country,
    DateTime? createdAt,
    List<Contact>? contacts,
  }) {
    return Client(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      type: type ?? this.type,
      taxId: taxId ?? this.taxId,
      alias: alias ?? this.alias,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      createdAt: createdAt ?? this.createdAt,
      contacts: contacts ?? this.contacts,
    );
  }

  @override
  List<Object?> get props => [
    id,
    ownerId,
    name,
    type,
    taxId,
    alias,
    email,
    phone,
    address,
    city,
    state,
    country,
    createdAt,
    contacts,
  ];
}

class Contact extends Equatable {
  final String id;
  final String clientId;
  final String name;
  final String? role;
  final String? email;
  final String? phone;
  final String? department;
  final bool isPrimary;
  final DateTime createdAt;

  const Contact({
    required this.id,
    required this.clientId,
    required this.name,
    this.role,
    this.email,
    this.phone,
    this.department,
    required this.isPrimary,
    required this.createdAt,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'],
      clientId: json['client_id'],
      name: json['name'],
      role: json['role'],
      email: json['email'],
      phone: json['phone'],
      department: json['department'],
      isPrimary: json['is_primary'] == true,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'client_id': clientId,
      'name': name,
      'role': role,
      'email': email,
      'phone': phone,
      'department': department,
      'is_primary': isPrimary,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Contact copyWith({
    String? id,
    String? clientId,
    String? name,
    String? role,
    String? email,
    String? phone,
    String? department,
    bool? isPrimary,
    DateTime? createdAt,
  }) {
    return Contact(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      name: name ?? this.name,
      role: role ?? this.role,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      isPrimary: isPrimary ?? this.isPrimary,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Helper to get initial
  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  @override
  List<Object?> get props => [
    id,
    clientId,
    name,
    role,
    email,
    phone,
    department,
    isPrimary,
    createdAt,
  ];
}
