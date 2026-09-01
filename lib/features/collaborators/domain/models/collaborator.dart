class Collaborator {
  final String id;
  final String userId;
  final String fullName;
  final String? identificationId;
  final String? phone;
  final String? email;
  final String? charge;
  final bool isActive;
  final bool isUserRecord;

  Collaborator({
    required this.id,
    required this.userId,
    required this.fullName,
    this.identificationId,
    this.phone,
    this.email,
    this.charge,
    required this.isActive,
    this.isUserRecord = false,
  });

  factory Collaborator.fromJson(Map<String, dynamic> json) {
    return Collaborator(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      identificationId: json['identification_id'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      charge: json['charge'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isUserRecord: json['is_user_record'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'identification_id': identificationId,
      'phone': phone,
      'email': email,
      'charge': charge,
      'is_active': isActive,
      'is_user_record': isUserRecord,
    };
  }

  Collaborator copyWith({
    String? id,
    String? userId,
    String? fullName,
    String? identificationId,
    String? phone,
    String? email,
    String? charge,
    bool? isActive,
    bool? isUserRecord,
  }) {
    return Collaborator(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      identificationId: identificationId ?? this.identificationId,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      charge: charge ?? this.charge,
      isActive: isActive ?? this.isActive,
      isUserRecord: isUserRecord ?? this.isUserRecord,
    );
  }
}
