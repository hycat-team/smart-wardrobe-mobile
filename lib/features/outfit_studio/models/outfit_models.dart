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

/// Món của thương hiệu — BE thay thế `fashionItem` bằng `brandItem` chứ không
/// thêm bên cạnh (spec 015 — FR-018, khẳng định sau khi đọc
/// `dto/recommendation.go` ở repo máy chủ).
class RecommendedBrandItemBrief {
  final String id;
  final RecommendedCategoryBrief? category;
  final String? imageUrl;
  final String? color;
  final String? brandName;
  final double? price;

  const RecommendedBrandItemBrief({
    required this.id,
    this.category,
    this.imageUrl,
    this.color,
    this.brandName,
    this.price,
  });

  factory RecommendedBrandItemBrief.fromJson(Map<String, dynamic> json) {
    return RecommendedBrandItemBrief(
      id: json['id']?.toString() ?? '',
      category: json['category'] is Map<String, dynamic>
          ? RecommendedCategoryBrief.fromJson(
              json['category'] as Map<String, dynamic>)
          : null,
      imageUrl: json['imageUrl'] ?? json['image_url'],
      color: json['color'],
      brandName: json['brandName'] ?? json['brand'],
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
    );
  }
}

class RecommendedItemRes {
  final String id;
  final String itemContext;
  final RecommendedFashionItemBrief? fashionItem;

  /// Spec 015 — FR-018: lấy ảnh được từ cả món tủ đồ lẫn món thương hiệu.
  final RecommendedBrandItemBrief? brandItem;

  const RecommendedItemRes({
    required this.id,
    this.itemContext = 'user_wardrobe',
    this.fashionItem,
    this.brandItem,
  });

  /// Nhãn hiển thị, xét cả món tủ đồ lẫn món thương hiệu (FR-018).
  String get displayName {
    final color = fashionItem?.color ?? brandItem?.color ?? '';
    final cat = fashionItem?.category?.name ??
        brandItem?.category?.name ??
        (fashionItem == null && brandItem == null ? null : 'Món đồ');
    if (cat == null) return 'Món đồ thời trang';
    return color.isNotEmpty ? '$cat - $color' : cat;
  }

  /// Ưu tiên ảnh món tủ đồ, thiếu thì lấy ảnh món thương hiệu (FR-018).
  String get imageUrl =>
      fashionItem?.imageUrl ??
      brandItem?.imageUrl ??
      '';

  factory RecommendedItemRes.fromJson(Map<String, dynamic> json) {
    return RecommendedItemRes(
      id: json['id']?.toString() ?? '',
      itemContext: json['itemContext']?.toString() ?? 'user_wardrobe',
      fashionItem: json['fashionItem'] != null
          ? RecommendedFashionItemBrief.fromJson(json['fashionItem'] as Map<String, dynamic>)
          : null,
      brandItem: json['brandItem'] != null
          ? RecommendedBrandItemBrief.fromJson(json['brandItem'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Nguồn nhãn vai trò **duy nhất** của ứng dụng (spec 015 — FR-034).
///
/// Cả màn Studio và màn trò chuyện stylist đều gọi hàm này, nên không thể xuất
/// hiện hai bảng ánh xạ song song cho cùng một vai trò.
String outfitRoleLabelVi(String role) => RecommendedItemGroup.roleLabelVi(role);

class RecommendedItemGroup {
  final String role;
  RecommendedItemRes? primary;
  final List<RecommendedItemRes> alternatives;

  RecommendedItemGroup({
    required this.role,
    this.primary,
    this.alternatives = const [],
  });

  /// Nhãn tiếng Việt của vai trò.
  ///
  /// Spec 015 — FR-031: bảng ánh xạ **đóng**, lấy đúng điển từ vai trò mà máy
  /// chủ trả về (`CategorySlugToWearingRole`: top / bottom / fullbody / outerwear /
  /// footwear / headwear / accessory, cộng `other` cho slug lạ).
  ///
  /// Trước đây thiếu `headwear` nên mũ rơi xuống `default` và hiện ra chữ
  /// `HEADWEAR`/`OTHER` cho người dùng — lỗi đã quan sát thấy.
  ///
  /// FR-032: vai trò **không có trong bảng** thì trả về **nguyên chuỗi gốc** máy
  /// chủ gửi (không ẩn, không upper-case) để lộ ra được khi máy chủ thêm vai trò mới.
  static String roleLabelVi(String role) {
    switch (role.trim().toLowerCase()) {
      case 'top':
        return 'Áo';
      case 'bottom':
        return 'Quần / Váy';
      case 'fullbody':
        return 'Váy liền / Đầm';
      case 'outerwear':
        return 'Áo khoác';
      case 'footwear':
        return 'Giày dép';
      case 'headwear':
        return 'Mũ / Nón';
      case 'accessory':
        return 'Phụ kiện';
      case 'other':
        return 'Món khác';
      default:
        // FR-032: giữ nguyên chuỗi gốc.
        return role;
    }
  }

  String get roleDisplay => roleLabelVi(role);

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

  /// Máy chủ sinh sẵn bộ gợi ý này (thường khi hết hạn mức) — phải gắn nhãn
  /// dự phòng, không trình bày như gợi ý chuẩn.
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
      // Spec 015 — FR-029: chấp nhận CẢ `fallback` (tên trường máy chủ gửi, xem
      // `dto/recommendation.go`) lẫn `isFallback` (khoá cũ của ứng dụng).
      //
      // Bug cũ chỉ đọc `isFallback` trong khi máy chủ không bao giờ gửi khoá đó,
      // nên `isFallback` LUÔN false và gợi ý dự phòng bị trình bày y như gợi ý
      // thật của stylist.
      isFallback: data['fallback'] is bool
          ? data['fallback'] as bool
          : (data['isFallback'] is bool ? data['isFallback'] as bool : false),
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
  final double baseScale;
  final double boxRatioW;
  final double boxRatioH;

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
    this.baseScale = 100.0,
    this.boxRatioW = 2.0,
    this.boxRatioH = 2.0,
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
    double? baseScale,
    double? boxRatioW,
    double? boxRatioH,
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
      baseScale: baseScale ?? this.baseScale,
      boxRatioW: boxRatioW ?? this.boxRatioW,
      boxRatioH: boxRatioH ?? this.boxRatioH,
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
      name: json['name']?.toString() ?? 'Bộ phối',
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
