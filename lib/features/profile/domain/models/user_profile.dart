class UserProfile {
  final String id;
  final String? firstName;
  final String? lastName;
  final String? gender;
  final DateTime? birthDate;
  final String? nationalId;
  final String? avatarUrl;
  final String? phone;
  final String? secondaryPhone;
  final String? occupation;
  final String? occupationId;
  final List<String> secondaryOccupations;
  final List<String> secondaryOccupationIds;
  final String? mainAddress;
  final String? mainCity;
  final String? mainState;
  final String? mainCountry;
  final bool isBusinessOwner;
  final String? companyName;
  final String? companyRif;
  final String? companyAddress;
  final String? companyLogoUrl;
  final String verificationStatus;
  final String? verificationType;
  final int? userNumber;
  final DateTime? updatedAt;
  final DateTime? createdAt;

  UserProfile({
    required this.id,
    this.firstName,
    this.lastName,
    this.gender,
    this.birthDate,
    this.nationalId,
    this.avatarUrl,
    this.phone,
    this.secondaryPhone,
    this.occupation,
    this.occupationId,
    this.secondaryOccupations = const [],
    this.secondaryOccupationIds = const [],
    this.mainAddress,
    this.mainCity,
    this.mainState,
    this.mainCountry,
    this.isBusinessOwner = false,
    this.companyName,
    this.companyRif,
    this.companyAddress,
    this.companyLogoUrl,
    this.verificationStatus = 'unverified',
    this.verificationType,
    this.userNumber,
    this.updatedAt,
    this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      gender: json['gender'] as String?,
      birthDate: json['birth_date'] != null
          ? DateTime.tryParse(json['birth_date'] as String)
          : null,
      nationalId: json['national_id'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      phone: json['phone'] as String?,
      secondaryPhone: json['secondary_phone'] as String?,
      occupation: json['occupation'] as String?,
      occupationId: json['occupation_id'] as String?,
      secondaryOccupations:
          (json['secondary_occupations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      secondaryOccupationIds:
          (json['secondary_occupation_ids'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      mainAddress: json['main_address'] as String?,
      mainCity: json['main_city'] as String?,
      mainState: json['main_state'] as String?,
      mainCountry: json['main_country'] as String?,
      isBusinessOwner: json['is_business_owner'] as bool? ?? false,
      companyName: json['company_name'] as String?,
      companyRif: json['company_rif'] as String?,
      companyAddress: json['company_address'] as String?,
      companyLogoUrl: json['company_logo_url'] as String?,
      verificationStatus:
          json['verification_status'] as String? ?? 'unverified',
      verificationType: json['verification_type'] as String?,
      userNumber: json['user_number'] as int?,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'gender': gender,
      'birth_date': birthDate?.toIso8601String(),
      'national_id': nationalId,
      'avatar_url': avatarUrl,
      'phone': phone,
      'secondary_phone': secondaryPhone,
      // 'occupation': occupation, // ELIMINADO: No existe en la BD
      'occupation_id': occupationId,
      // 'secondary_occupations': secondaryOccupations, // ELIMINADO: No existe en la BD
      'secondary_occupation_ids': secondaryOccupationIds,
      'main_address': mainAddress,
      'main_city': mainCity,
      'main_state': mainState,
      'main_country': mainCountry,
      'is_business_owner': isBusinessOwner,
      'company_name': companyName,
      'company_rif': companyRif,
      'company_address': companyAddress,
      'company_logo_url': companyLogoUrl,
      'verification_status': verificationStatus,
      'verification_type': verificationType,
      'user_number': userNumber,
      'updated_at': updatedAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  UserProfile copyWith({
    dynamic firstName = _sentinel,
    dynamic lastName = _sentinel,
    dynamic gender = _sentinel,
    dynamic birthDate = _sentinel,
    dynamic nationalId = _sentinel,
    dynamic avatarUrl = _sentinel,
    dynamic phone = _sentinel,
    dynamic secondaryPhone = _sentinel,
    dynamic occupation = _sentinel,
    dynamic occupationId = _sentinel,
    dynamic secondaryOccupations = _sentinel,
    dynamic secondaryOccupationIds = _sentinel,
    dynamic mainAddress = _sentinel,
    dynamic mainCity = _sentinel,
    dynamic mainState = _sentinel,
    dynamic mainCountry = _sentinel,
    bool? isBusinessOwner,
    dynamic companyName = _sentinel,
    dynamic companyRif = _sentinel,
    dynamic companyAddress = _sentinel,
    dynamic companyLogoUrl = _sentinel,
    String? verificationStatus,
    dynamic verificationType = _sentinel,
    dynamic userNumber = _sentinel,
  }) {
    return UserProfile(
      id: id,
      firstName: firstName == _sentinel ? this.firstName : firstName as String?,
      lastName: lastName == _sentinel ? this.lastName : lastName as String?,
      gender: gender == _sentinel ? this.gender : gender as String?,
      birthDate: birthDate == _sentinel
          ? this.birthDate
          : birthDate as DateTime?,
      nationalId: nationalId == _sentinel
          ? this.nationalId
          : nationalId as String?,
      avatarUrl: avatarUrl == _sentinel ? this.avatarUrl : avatarUrl as String?,
      phone: phone == _sentinel ? this.phone : phone as String?,
      secondaryPhone: secondaryPhone == _sentinel
          ? this.secondaryPhone
          : secondaryPhone as String?,
      occupation: occupation == _sentinel
          ? this.occupation
          : occupation as String?,
      occupationId: occupationId == _sentinel
          ? this.occupationId
          : occupationId as String?,
      secondaryOccupations: secondaryOccupations == _sentinel
          ? this.secondaryOccupations
          : secondaryOccupations as List<String>,
      secondaryOccupationIds: secondaryOccupationIds == _sentinel
          ? this.secondaryOccupationIds
          : secondaryOccupationIds as List<String>,
      mainAddress: mainAddress == _sentinel
          ? this.mainAddress
          : mainAddress as String?,
      mainCity: mainCity == _sentinel ? this.mainCity : mainCity as String?,
      mainState: mainState == _sentinel ? this.mainState : mainState as String?,
      mainCountry: mainCountry == _sentinel
          ? this.mainCountry
          : mainCountry as String?,
      isBusinessOwner: isBusinessOwner ?? this.isBusinessOwner,
      companyName: companyName == _sentinel
          ? this.companyName
          : companyName as String?,
      companyRif: companyRif == _sentinel
          ? this.companyRif
          : companyRif as String?,
      companyAddress: companyAddress == _sentinel
          ? this.companyAddress
          : companyAddress as String?,
      companyLogoUrl: companyLogoUrl == _sentinel
          ? this.companyLogoUrl
          : companyLogoUrl as String?,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verificationType: verificationType == _sentinel
          ? this.verificationType
          : verificationType as String?,
      userNumber: userNumber == _sentinel
          ? this.userNumber
          : userNumber as int?,
      updatedAt: updatedAt,
      createdAt: createdAt,
    );
  }
}

const _sentinel = Object();
