import 'dart:convert';

class DraftData {
  final String moduleKey;
  final DateTime savedAt;
  final int tabIndex;
  final String? summaryTitle;
  final Map<String, dynamic> data;

  const DraftData({
    required this.moduleKey,
    required this.savedAt,
    this.tabIndex = 0,
    this.summaryTitle,
    required this.data,
  });

  Map<String, dynamic> toMap() {
    return {
      'module_key': moduleKey,
      'saved_at': savedAt.toIso8601String(),
      'tab_index': tabIndex,
      'summary_title': summaryTitle,
      'data': data,
    };
  }

  factory DraftData.fromMap(Map<String, dynamic> map) {
    return DraftData(
      moduleKey: map['module_key'] as String,
      savedAt: DateTime.tryParse(map['saved_at'] as String? ?? '') ?? DateTime.now(),
      tabIndex: (map['tab_index'] as num?)?.toInt() ?? 0,
      summaryTitle: map['summary_title'] as String?,
      data: Map<String, dynamic>.from(map['data'] as Map? ?? {}),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory DraftData.fromJson(String source) {
    return DraftData.fromMap(jsonDecode(source) as Map<String, dynamic>);
  }
}
