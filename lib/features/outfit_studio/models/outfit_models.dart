class AIOutfitRecommendationReq {
  final String? occasion;
  final String? styleTarget;
  final String? season;
  final String? weather;
  final String? colorTone;
  final String? details;
  final bool? includeBrandItems;

  const AIOutfitRecommendationReq({
    this.occasion,
    this.styleTarget,
    this.season,
    this.weather,
    this.colorTone,
    this.details,
    this.includeBrandItems,
  });

  Map<String, dynamic> toJson() => {
        if (occasion != null && occasion!.isNotEmpty) 'occasion': occasion,
        if (styleTarget != null && styleTarget!.isNotEmpty) 'styleTarget': styleTarget,
        if (season != null && season!.isNotEmpty) 'season': season,
        if (weather != null && weather!.isNotEmpty) 'weather': weather,
        if (colorTone != null && colorTone!.isNotEmpty) 'colorTone': colorTone,
        if (details != null && details!.isNotEmpty) 'details': details,
        if (includeBrandItems != null) 'include_brand_items': includeBrandItems,
      };
}

class RecommendedCategoryBrief {
  final String id;
  final String name;
  final String slug;

  const RecommendedCategoryBrief({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory RecommendedCategoryBrief.fromJson(Map<String, dynamic> json) {
    return RecommendedCategoryBrief(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
    );
  }
}

class RecommendedFashionItemBrief {
  final String id;
  final String imageUrl;
  final String? color;
  final String? colorHex;
  final String? style;
  final RecommendedCategoryBrief? category;

  const RecommendedFashionItemBrief({
    required this.id,
    required this.imageUrl,
    this.color,
    this.colorHex,
    this.style,
    this.category,
  });

  factory RecommendedFashionItemBrief.fromJson(Map<String, dynamic> json) {
    return RecommendedFashionItemBrief(
      id: json['id']?.toString() ?? '',
      imageUrl: json['imageUrl'] ?? json['image_url'] ?? '',
      color: json['color'],
      colorHex: json['colorHex'] ?? json['color_hex'],
      style: json['style'],
      category: json['category'] != null
          ? RecommendedCategoryBrief.fromJson(json['category'] as Map<String, dynamic>)
          : null,
    );
  }
}

class RecommendedItemRes {
  final String id;
  final String itemContext;
  final RecommendedFashionItemBrief? fashionItem;

  const RecommendedItemRes({
    required this.id,
    this.itemContext = 'user_wardrobe',
    this.fashionItem,
  });

  String get displayName {
    if (fashionItem != null) {
      final cat = fashionItem!.category?.name ?? 'Món đồ';
      final color = fashionItem!.color ?? '';
      return color.isNotEmpty ? '$cat - $color' : cat;
    }
    return 'Món đồ thời trang';
  }

  String get imageUrl => fashionItem?.imageUrl ?? '';

  factory RecommendedItemRes.fromJson(Map<String, dynamic> json) {
    return RecommendedItemRes(
      id: json['id']?.toString() ?? '',
      itemContext: json['itemContext']?.toString() ?? 'user_wardrobe',
      fashionItem: json['fashionItem'] != null
          ? RecommendedFashionItemBrief.fromJson(json['fashionItem'] as Map<String, dynamic>)
          : null,
    );
  }
}

class RecommendedItemGroup {
  final String role;
  RecommendedItemRes? primary;
  final List<RecommendedItemRes> alternatives;

  RecommendedItemGroup({
    required this.role,
    this.primary,
    this.alternatives = const [],
  });

  String get roleDisplay {
    switch (role.toLowerCase()) {
      case 'top':
        return 'Áo';
      case 'bottom':
        return 'Quần / Váy';
      case 'fullbody':
        return 'Váy liền / Đầm';
      case 'footwear':
        return 'Giày dép';
      case 'outerwear':
        return 'Áo khoác';
      case 'accessory':
        return 'Phụ kiện';
      default:
        return role.toUpperCase();
    }
  }

  factory RecommendedItemGroup.fromJson(Map<String, dynamic> json) {
    return RecommendedItemGroup(
      role: json['role']?.toString() ?? '',
      primary: json['primary'] != null
          ? RecommendedItemRes.fromJson(json['primary'] as Map<String, dynamic>)
          : null,
      alternatives: json['alternatives'] is List
          ? (json['alternatives'] as List)
              .map((i) => RecommendedItemRes.fromJson(i as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}

class RecommendedOutfitRes {
  final String title;
  final String explanation;
  final List<RecommendedItemGroup> items;
  final bool isFallback;
  final int remainingQuota;

  const RecommendedOutfitRes({
    required this.title,
    required this.explanation,
    required this.items,
    this.isFallback = false,
    this.remainingQuota = 0,
  });

  factory RecommendedOutfitRes.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] : json;
    return RecommendedOutfitRes(
      title: data['title']?.toString() ?? 'Set đồ gợi ý',
      explanation: data['explanation']?.toString() ?? '',
      items: data['items'] is List
          ? (data['items'] as List)
              .map((g) => RecommendedItemGroup.fromJson(g as Map<String, dynamic>))
              .toList()
          : [],
      isFallback: data['isFallback'] is bool ? data['isFallback'] : false,
      remainingQuota: data['remainingQuota'] is int
          ? data['remainingQuota']
          : int.tryParse(data['remainingQuota']?.toString() ?? '0') ?? 0,
    );
  }
}

class SaveOutfitItemReq {
  final String fashionItemId;
  final double positionX;
  final double positionY;
  final double scale;
  final int layerOrder;

  const SaveOutfitItemReq({
    required this.fashionItemId,
    this.positionX = 0,
    this.positionY = 0,
    this.scale = 1.0,
    this.layerOrder = 1,
  });

  Map<String, dynamic> toJson() => {
        'fashionItemId': fashionItemId,
        'positionX': positionX,
        'positionY': positionY,
        'scale': scale,
        'layerOrder': layerOrder,
      };
}

class SaveOutfitReq {
  final String name;
  final String? description;
  final String? coverImageUrl;
  final String? coverPublicId;
  final List<SaveOutfitItemReq> items;

  const SaveOutfitReq({
    required this.name,
    this.description,
    this.coverImageUrl,
    this.coverPublicId,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        if (description != null && description!.isNotEmpty) 'description': description,
        if (coverImageUrl != null && coverImageUrl!.isNotEmpty) 'coverImageUrl': coverImageUrl,
        if (coverPublicId != null && coverPublicId!.isNotEmpty) 'coverPublicId': coverPublicId,
        'items': items.map((i) => i.toJson()).toList(),
      };
}

class CanvasItem {
  final String id;
  final String fashionItemId;
  final String imageUrl;
  final String name;
  final String role;
  double positionX;
  double positionY;
  double scale;
  int layerOrder;

  CanvasItem({
    required this.id,
    required this.fashionItemId,
    required this.imageUrl,
    required this.name,
    this.role = 'item',
    this.positionX = 0,
    this.positionY = 0,
    this.scale = 1.0,
    this.layerOrder = 1,
  });

  CanvasItem copyWith({
    String? id,
    String? fashionItemId,
    String? imageUrl,
    String? name,
    String? role,
    double? positionX,
    double? positionY,
    double? scale,
    int? layerOrder,
  }) {
    return CanvasItem(
      id: id ?? this.id,
      fashionItemId: fashionItemId ?? this.fashionItemId,
      imageUrl: imageUrl ?? this.imageUrl,
      name: name ?? this.name,
      role: role ?? this.role,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      scale: scale ?? this.scale,
      layerOrder: layerOrder ?? this.layerOrder,
    );
  }
}

class OutfitItemDetailModel {
  final String id;
  final String itemContext;
  final double positionX;
  final double positionY;
  final double scale;
  final int layerOrder;
  final RecommendedFashionItemBrief? fashionItem;

  const OutfitItemDetailModel({
    required this.id,
    this.itemContext = 'user_wardrobe',
    this.positionX = 0,
    this.positionY = 0,
    this.scale = 1.0,
    this.layerOrder = 1,
    this.fashionItem,
  });

  factory OutfitItemDetailModel.fromJson(Map<String, dynamic> json) {
    return OutfitItemDetailModel(
      id: json['id']?.toString() ?? '',
      itemContext: json['itemContext']?.toString() ?? 'user_wardrobe',
      positionX: json['positionX'] is num ? (json['positionX'] as num).toDouble() : 0,
      positionY: json['positionY'] is num ? (json['positionY'] as num).toDouble() : 0,
      scale: json['scale'] is num ? (json['scale'] as num).toDouble() : 1.0,
      layerOrder: json['layerOrder'] is int ? json['layerOrder'] : 1,
      fashionItem: json['fashionItem'] != null
          ? RecommendedFashionItemBrief.fromJson(json['fashionItem'] as Map<String, dynamic>)
          : null,
    );
  }
}

class UserOutfitModel {
  final String id;
  final String name;
  final String? description;
  final String? coverImageUrl;
  final int status;
  final String? createdAt;
  final List<OutfitItemDetailModel> items;

  const UserOutfitModel({
    required this.id,
    required this.name,
    this.description,
    this.coverImageUrl,
    this.status = 1,
    this.createdAt,
    this.items = const [],
  });

  String get formattedDate {
    if (createdAt == null || createdAt!.isEmpty) return '';
    try {
      final dt = DateTime.parse(createdAt!).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return createdAt!;
    }
  }

  factory UserOutfitModel.fromJson(Map<String, dynamic> json) {
    return UserOutfitModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Outfit',
      description: json['description']?.toString(),
      coverImageUrl: json['coverImageUrl']?.toString() ?? json['cover_image_url']?.toString(),
      status: json['status'] is int ? json['status'] : 1,
      createdAt: json['createdAt']?.toString() ?? json['created_at']?.toString(),
      items: json['items'] is List
          ? (json['items'] as List)
              .map((i) => OutfitItemDetailModel.fromJson(i as Map<String, dynamic>))
              .toList()
          : [],
    );
  }
}
