class Collaborator {
  final String id;
  final String fullName;
  final String? identificationId;
  final String? phone;
  final String? email;
  final String? charge;
  final bool isActive;

  Collaborator({
    required this.id,
    required this.fullName,
    this.identificationId,
    this.phone,
    this.email,
    this.charge,
    required this.isActive,
  });

  factory Collaborator.fromJson(Map<String, dynamic> json) {
    return Collaborator(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      identificationId: json['identification_id'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      charge: json['charge'] as String?,
      isActive: json['is_active'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'identification_id': identificationId,
      'phone': phone,
      'email': email,
      'charge': charge,
      'is_active': isActive,
    };
  }
}
