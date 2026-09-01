enum AdActionType {
  externalUrl,
  internalSupplier,
  internalProduct,
  bottomSheet,
  none;

  static AdActionType fromString(String? value) {
    switch (value) {
      case 'internal_supplier':
        return AdActionType.internalSupplier;
      case 'internal_product':
        return AdActionType.internalProduct;
      case 'bottom_sheet':
        return AdActionType.bottomSheet;
      case 'none':
        return AdActionType.none;
      case 'external_url':
      default:
        return AdActionType.externalUrl;
    }
  }

  String toDbString() {
    switch (this) {
      case AdActionType.internalSupplier:
        return 'internal_supplier';
      case AdActionType.internalProduct:
        return 'internal_product';
      case AdActionType.bottomSheet:
        return 'bottom_sheet';
      case AdActionType.none:
        return 'none';
      case AdActionType.externalUrl:
        return 'external_url';
    }
  }
}

class AdBanner {
  final String id;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? supplierId;
  final String? advertiserName;
  final List<String> sectorIds;
  final List<String> keywords;
  final List<String> categoryTags;
  final AdActionType actionType;
  final String? actionPayload;
  final int priority;

  const AdBanner({
    required this.id,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.supplierId,
    this.advertiserName,
    this.sectorIds = const [],
    this.keywords = const [],
    this.categoryTags = const [],
    this.actionType = AdActionType.externalUrl,
    this.actionPayload,
    this.priority = 0,
  });

  factory AdBanner.fromJson(Map<String, dynamic> json) {
    return AdBanner(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String?,
      imageUrl: json['image_url'] as String?,
      supplierId: json['supplier_id'] as String?,
      advertiserName: json['advertiser_name'] as String?,
      sectorIds: (json['sector_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      keywords: (json['keywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      categoryTags: (json['category_tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      actionType: AdActionType.fromString(json['action_type'] as String?),
      actionPayload: json['action_payload'] as String?,
      priority: (json['priority'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'image_url': imageUrl,
      'supplier_id': supplierId,
      'advertiser_name': advertiserName,
      'sector_ids': sectorIds,
      'keywords': keywords,
      'category_tags': categoryTags,
      'action_type': actionType.toDbString(),
      'action_payload': actionPayload,
      'priority': priority,
    };
  }
}
