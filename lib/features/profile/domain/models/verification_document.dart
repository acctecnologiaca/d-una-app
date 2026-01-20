class VerificationDocument {
  final String id;
  final String userId;
  final String documentType;
  final String filePath;
  final String status;
  final DateTime? createdAt;

  VerificationDocument({
    required this.id,
    required this.userId,
    required this.documentType,
    required this.filePath,
    required this.status,
    this.createdAt,
  });

  factory VerificationDocument.fromJson(Map<String, dynamic> json) {
    return VerificationDocument(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      documentType: json['document_type'] as String,
      filePath: json['file_path'] as String,
      status: json['status'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'document_type': documentType,
      'file_path': filePath,
      'status': status,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
