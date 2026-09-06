class UserCompany {
  final String id;
  final String userId;
  final String companyName;
  final String? companyRif;
  final String? companyAddress;
  final String? companyLogoUrl;
  final String verificationStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserCompany({
    required this.id,
    required this.userId,
    required this.companyName,
    this.companyRif,
    this.companyAddress,
    this.companyLogoUrl,
    this.verificationStatus = 'unverified',
    this.createdAt,
    this.updatedAt,
  });

  factory UserCompany.fromJson(Map<String, dynamic> json) {
    return UserCompany(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      companyName: json['company_name'] as String? ?? '',
      companyRif: json['company_rif'] as String?,
      companyAddress: json['company_address'] as String?,
      companyLogoUrl: json['company_logo_url'] as String?,
      verificationStatus:
          json['verification_status'] as String? ?? 'unverified',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'company_name': companyName,
      'company_rif': companyRif,
      'company_address': companyAddress,
      'company_logo_url': companyLogoUrl,
      'verification_status': verificationStatus,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  UserCompany copyWith({
    String? id,
    String? userId,
    dynamic companyName = _sentinel,
    dynamic companyRif = _sentinel,
    dynamic companyAddress = _sentinel,
    dynamic companyLogoUrl = _sentinel,
    String? verificationStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserCompany(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      companyName: companyName == _sentinel
          ? this.companyName
          : companyName as String,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

const _sentinel = Object();
