import 'package:equatable/equatable.dart';

enum QuickPhraseFieldType {
  request(
    dbValue: 'request',
    label: 'Solicitud',
    shortLabel: 'Solicitud',
    description: 'Motivo o requerimiento reportado por el cliente',
  ),
  work(
    dbValue: 'work',
    label: 'Diagnóstico y servicio realizado',
    shortLabel: 'Diagnóstico',
    description: 'Detalle de la falla detectada y solución técnica ejecutada',
  ),
  recommendation(
    dbValue: 'recommendation',
    label: 'Recomendaciones',
    shortLabel: 'Recomendaciones',
    description: 'Observaciones preventivas o sugerencias de mejora al cliente',
  );

  final String dbValue;
  final String label;
  final String shortLabel;
  final String description;

  const QuickPhraseFieldType({
    required this.dbValue,
    required this.label,
    required this.shortLabel,
    required this.description,
  });

  static QuickPhraseFieldType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'work':
      case 'diagnostico':
      case 'diagnóstico':
        return QuickPhraseFieldType.work;
      case 'recommendation':
      case 'recommendations':
      case 'recomendacion':
      case 'recomendaciones':
        return QuickPhraseFieldType.recommendation;
      case 'request':
      case 'solicitud':
      default:
        return QuickPhraseFieldType.request;
    }
  }
}

class QuickPhrase extends Equatable {
  final String id;
  final String userId;
  final QuickPhraseFieldType fieldType;
  final String? categoryId;
  final String? categoryName;
  final String phrase;
  final int orderIndex;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const QuickPhrase({
    required this.id,
    required this.userId,
    required this.fieldType,
    this.categoryId,
    this.categoryName,
    required this.phrase,
    this.orderIndex = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory QuickPhrase.fromJson(Map<String, dynamic> json) {
    String? catName;
    if (json['categories'] != null && json['categories'] is Map) {
      catName = json['categories']['name'] as String?;
    } else if (json['category_name'] != null) {
      catName = json['category_name'] as String?;
    }

    return QuickPhrase(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fieldType: QuickPhraseFieldType.fromString(json['field_type'] as String?),
      categoryId: json['category_id'] as String?,
      categoryName: catName,
      phrase: json['phrase'] as String? ?? '',
      orderIndex: json['order_index'] as int? ?? 0,
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
      'field_type': fieldType.dbValue,
      'category_id': categoryId,
      'phrase': phrase,
      'order_index': orderIndex,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
    };
  }

  QuickPhrase copyWith({
    String? id,
    String? userId,
    QuickPhraseFieldType? fieldType,
    String? categoryId,
    String? categoryName,
    String? phrase,
    int? orderIndex,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuickPhrase(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fieldType: fieldType ?? this.fieldType,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      phrase: phrase ?? this.phrase,
      orderIndex: orderIndex ?? this.orderIndex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    fieldType,
    categoryId,
    categoryName,
    phrase,
    orderIndex,
    createdAt,
    updatedAt,
  ];
}

class UniversalQuickPhrase {
  final QuickPhraseFieldType fieldType;
  final String phrase;

  const UniversalQuickPhrase({required this.fieldType, required this.phrase});
}

const List<UniversalQuickPhrase> kUniversalDefaultPhrases = [
  // 1. Solicitud (Request)
  UniversalQuickPhrase(
    fieldType: QuickPhraseFieldType.request,
    phrase: 'Mantenimiento preventivo programado',
  ),
  UniversalQuickPhrase(
    fieldType: QuickPhraseFieldType.request,
    phrase: 'Falla operativa general reportada en el equipo',
  ),
  UniversalQuickPhrase(
    fieldType: QuickPhraseFieldType.request,
    phrase: 'Ruido y vibración anormal durante la operación',
  ),
  UniversalQuickPhrase(
    fieldType: QuickPhraseFieldType.request,
    phrase: 'Equipo no enciende / corte de energía',
  ),
  UniversalQuickPhrase(
    fieldType: QuickPhraseFieldType.request,
    phrase: 'Revisión periódica y diagnóstico técnico',
  ),
  UniversalQuickPhrase(
    fieldType: QuickPhraseFieldType.request,
    phrase: 'Fuga o goteo de fluido detectado',
  ),

  // 2. Diagnóstico y Servicio Realizado (Work)
  UniversalQuickPhrase(
    fieldType: QuickPhraseFieldType.work,
    phrase: 'Se realizó inspección visual y pruebas operativas iniciales',
  ),
  UniversalQuickPhrase(
    fieldType: QuickPhraseFieldType.work,
    phrase: 'Se procedió con limpieza general, ajuste de conexiones y reapriete',
  ),
  UniversalQuickPhrase(
    fieldType: QuickPhraseFieldType.work,
    phrase: 'Se detectó componente averiado y se efectuó su reemplazo',
  ),
  UniversalQuickPhrase(
    fieldType: QuickPhraseFieldType.work,
    phrase: 'Se corrigieron fugas y se realizaron pruebas de estanqueidad',
  ),
  UniversalQuickPhrase(
    fieldType: QuickPhraseFieldType.work,
    phrase: 'Equipo puesto en marcha con parámetros dentro de rango nominal',
  ),
  UniversalQuickPhrase(
    fieldType: QuickPhraseFieldType.work,
    phrase: 'Se realizaron mediciones de voltaje, corriente y temperatura',
  ),

  // 3. Recomendaciones Técnicas (Recommendation)
  UniversalQuickPhrase(
    fieldType: QuickPhraseFieldType.recommendation,
    phrase: 'Realizar mantenimiento preventivo en el próximo período programado',
  ),
  UniversalQuickPhrase(
    fieldType: QuickPhraseFieldType.recommendation,
    phrase: 'Mantener despejada el área de ventilación y libre de polvo',
  ),
  UniversalQuickPhrase(
    fieldType: QuickPhraseFieldType.recommendation,
    phrase: 'Monitorear temperatura y ruidos anormales durante la operación',
  ),
  UniversalQuickPhrase(
    fieldType: QuickPhraseFieldType.recommendation,
    phrase: 'Se sugiere reemplazo preventivo de componentes por desgaste',
  ),
  UniversalQuickPhrase(
    fieldType: QuickPhraseFieldType.recommendation,
    phrase: 'Operar el equipo dentro de las cargas y parámetros recomendados',
  ),
];
