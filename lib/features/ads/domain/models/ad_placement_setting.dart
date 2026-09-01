class AdPlacementSetting {
  final String placementKey;
  final String? parentModule;
  final String name;
  final bool isEnabled;

  const AdPlacementSetting({
    required this.placementKey,
    this.parentModule,
    required this.name,
    required this.isEnabled,
  });

  factory AdPlacementSetting.fromJson(Map<String, dynamic> json) {
    return AdPlacementSetting(
      placementKey: json['placement_key'] as String,
      parentModule: json['parent_module'] as String?,
      name: json['name'] as String? ?? '',
      isEnabled: json['is_enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'placement_key': placementKey,
      'parent_module': parentModule,
      'name': name,
      'is_enabled': isEnabled,
    };
  }
}
