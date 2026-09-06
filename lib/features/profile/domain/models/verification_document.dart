class VerificationDocument {
  final String id;
  final String userId;
  final String? companyId;
  final String documentType;
  final String filePath;
  final String status;
  final DateTime? createdAt;

  VerificationDocument({
    required this.id,
    required this.userId,
    this.companyId,
    required this.documentType,
    required this.filePath,
    required this.status,
    this.createdAt,
  });

  factory VerificationDocument.fromJson(Map<String, dynamic> json) {
    return VerificationDocument(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      companyId: json['company_id'] as String?,
      documentType: json['document_type'] as String,
      filePath: json['file_path'] as String,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'company_id': companyId,
      'document_type': documentType,
      'file_path': filePath,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  VerificationDocument copyWith({
    String? id,
    String? userId,
    dynamic companyId = _sentinel,
    String? documentType,
    String? filePath,
    String? status,
    DateTime? createdAt,
  }) {
    return VerificationDocument(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      companyId: companyId == _sentinel ? this.companyId : companyId as String?,
      documentType: documentType ?? this.documentType,
      filePath: filePath ?? this.filePath,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

const _sentinel = Object();
