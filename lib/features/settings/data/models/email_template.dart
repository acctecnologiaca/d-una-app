class EmailTemplate {
  final String id;
  final String userId;
  final String documentType;
  final String? subjectTemplate;
  final String? bodyTemplate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  EmailTemplate({
    required this.id,
    required this.userId,
    required this.documentType,
    this.subjectTemplate,
    this.bodyTemplate,
    this.createdAt,
    this.updatedAt,
  });

  factory EmailTemplate.fromJson(Map<String, dynamic> json) {
    return EmailTemplate(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      documentType: json['document_type'] as String,
      subjectTemplate: json['subject_template'] as String?,
      bodyTemplate: json['body_template'] as String?,
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
      'document_type': documentType,
      'subject_template': subjectTemplate,
      'body_template': bodyTemplate,
    };
  }

  EmailTemplate copyWith({
    String? subjectTemplate,
    String? bodyTemplate,
  }) {
    return EmailTemplate(
      id: id,
      userId: userId,
      documentType: documentType,
      subjectTemplate: subjectTemplate ?? this.subjectTemplate,
      bodyTemplate: bodyTemplate ?? this.bodyTemplate,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
