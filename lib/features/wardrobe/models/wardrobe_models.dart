import '../../../core/services/cloudinary_service.dart';
import 'package:intl/intl.dart';

class CategoryModel {
  final String id;
  final String name;
  final String slug;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      slug: json['slug'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
      };
}

class FashionItemModel {
  final String id;
  final String imageUrl;
  final String? color;
  final String? colorHex;
  final String? style;
  final String? material;
  final String? pattern;
  final String? fit;
  final String? seasonality;
  final String? description;
  final String? brandName;
  final CategoryModel? category;

  const FashionItemModel({
    required this.id,
    required this.imageUrl,
    this.color,
    this.colorHex,
    this.style,
    this.material,
    this.pattern,
    this.fit,
    this.seasonality,
    this.description,
    this.brandName,
    this.category,
  });

  factory FashionItemModel.fromJson(Map<String, dynamic> json) {
    String? brand;
    if (json['brandItem'] != null && json['brandItem'] is Map) {
      brand = json['brandItem']['brandName'] ?? json['brandItem']['brand_name'];
    }

    return FashionItemModel(
      id: json['id']?.toString() ?? '',
      imageUrl: json['imageUrl'] ?? json['image_url'] ?? '',
      color: json['color'],
      colorHex: json['colorHex'] ?? json['color_hex'],
      style: json['style'],
      material: json['material'],
      pattern: json['pattern'],
      fit: json['fit'],
      seasonality: json['seasonality'],
      description: json['description'],
      brandName: brand ?? json['brandName'] ?? json['brand_name'],
      category: json['category'] != null ? CategoryModel.fromJson(json['category']) : null,
    );
  }

  FashionItemModel copyWith({
    String? id,
    String? imageUrl,
    String? color,
    String? colorHex,
    String? style,
    String? material,
    String? pattern,
    String? fit,
    String? seasonality,
    String? description,
    String? brandName,
    CategoryModel? category,
  }) {
    return FashionItemModel(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      color: color ?? this.color,
      colorHex: colorHex ?? this.colorHex,
      style: style ?? this.style,
      material: material ?? this.material,
      pattern: pattern ?? this.pattern,
      fit: fit ?? this.fit,
      seasonality: seasonality ?? this.seasonality,
      description: description ?? this.description,
      brandName: brandName ?? this.brandName,
      category: category ?? this.category,
    );
  }
}

class WardrobeItemModel {
  final String id;
  final int status; // 0 = InWardrobe, 1 = Selling, 2 = Sold, 3 = Processing, 4 = Failed, 5 = NeedsReview
  final double? price;
  final bool isLocked;
  final String? taskId;
  final String? rawImageUrl;
  final FashionItemModel? fashionItem;
  final CategoryModel? category;
  final String? createdAt;
  final String? lastUsedAt;

  const WardrobeItemModel({
    required this.id,
    this.status = 0,
    this.price,
    this.isLocked = false,
    this.taskId,
    this.rawImageUrl,
    this.fashionItem,
    this.category,
    this.createdAt,
    this.lastUsedAt,
  });

  bool get isProcessing => status == 3;
  bool get isFailed => status == 4;
  bool get needsReview => status == 5;
  bool get isInWardrobe => status == 0;
  bool get isSelling => status == 1;
  bool get isSold => status == 2;

  String get displayTitle {
    if (isProcessing) {
      return 'Đang phân tích...';
    }
    if (needsReview) {
      final cat = category?.name ?? fashionItem?.category?.name;
      if (cat != null && cat.isNotEmpty) return '$cat (Cần xác nhận)';
      return 'Chờ chọn phân loại';
    }
    if (isFailed) {
      return 'Phân tích thất bại';
    }
    if (fashionItem != null) {
      final style = fashionItem!.style ?? '';
      final color = fashionItem!.color ?? '';
      final cat = category?.name ?? fashionItem?.category?.name ?? 'Món đồ';
      if (color.isNotEmpty || style.isNotEmpty) {
        return '$color $style $cat'.trim();
      }
      return cat;
    }
    return category?.name ?? 'Món đồ';
  }

  String get displayCategoryName {
    if (isProcessing) {
      return 'ĐANG XỬ LÝ...';
    }
    if (needsReview) {
      return (category?.name ?? fashionItem?.category?.name ?? 'CẦN KIỂM TRA').toUpperCase();
    }
    if (isFailed) {
      return 'LỖI PHÂN TÍCH';
    }
    return (category?.name ?? fashionItem?.category?.name ?? 'MÓN ĐỒ').toUpperCase();
  }

  String get displayImageUrl {
    String url = '';
    if (fashionItem?.imageUrl != null && fashionItem!.imageUrl.isNotEmpty) {
      url = fashionItem!.imageUrl;
    } else if (rawImageUrl != null && rawImageUrl!.isNotEmpty) {
      url = rawImageUrl!;
    }
    return applyCloudinaryBackgroundRemoval(url);
  }

  String get formattedPrice {
    if (price == null || price! <= 0) return 'Chưa có giá';
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    return formatter.format(price);
  }

  String get statusLabel {
    switch (status) {
      case 0:
        return 'Trong tủ đồ';
      case 1:
        return 'Đang bán';
      case 2:
        return 'Đã bán';
      case 3:
        return 'Đang phân tích';
      case 4:
        return 'Lỗi phân tích';
      case 5:
        return 'Cần chọn loại';
      default:
        return 'Khả dụng';
    }
  }

  WardrobeItemModel copyWith({
    String? id,
    int? status,
    double? price,
    bool? isLocked,
    String? taskId,
    String? rawImageUrl,
    FashionItemModel? fashionItem,
    CategoryModel? category,
    String? createdAt,
    String? lastUsedAt,
  }) {
    return WardrobeItemModel(
      id: id ?? this.id,
      status: status ?? this.status,
      price: price ?? this.price,
      isLocked: isLocked ?? this.isLocked,
      taskId: taskId ?? this.taskId,
      rawImageUrl: rawImageUrl ?? this.rawImageUrl,
      fashionItem: fashionItem ?? this.fashionItem,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  factory WardrobeItemModel.fromJson(Map<String, dynamic> json) {
    FashionItemModel? fItem;
    if (json['fashionItem'] != null && json['fashionItem'] is Map) {
      fItem = FashionItemModel.fromJson(json['fashionItem']);
    }

    CategoryModel? cat;
    if (json['category'] != null && json['category'] is Map) {
      cat = CategoryModel.fromJson(json['category']);
    } else if (fItem?.category != null) {
      cat = fItem!.category;
    }

    final rawImg = json['rawImageUrl']?.toString() ??
        json['imageUrl']?.toString() ??
        json['image_url']?.toString();

    return WardrobeItemModel(
      id: json['id']?.toString() ?? '',
      status: json['status'] is int ? json['status'] : 0,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      isLocked: json['isLocked'] == true,
      taskId: json['taskId']?.toString() ?? json['task_id']?.toString() ?? json['TaskID']?.toString(),
      rawImageUrl: rawImg,
      fashionItem: fItem,
      category: cat,
      createdAt: json['createdAt']?.toString(),
      lastUsedAt: json['lastUsedAt']?.toString(),
    );
  }
}

class BatchUploadItemResponse {
  final String id;
  final int status;
  final String? taskId;
  final String? fashionItemId;

  const BatchUploadItemResponse({
    required this.id,
    required this.status,
    this.taskId,
    this.fashionItemId,
  });

  factory BatchUploadItemResponse.fromJson(Map<String, dynamic> json) {
    return BatchUploadItemResponse(
      id: json['id']?.toString() ?? '',
      status: json['status'] is int ? json['status'] : 3,
      taskId: json['taskId']?.toString() ?? json['task_id']?.toString() ?? json['TaskID']?.toString(),
      fashionItemId: json['fashionItemId']?.toString() ?? json['fashion_item_id']?.toString(),
    );
  }
}

class WardrobeTaskSSEPayload {
  final String? taskId;
  final String? itemId;
  final String status;
  final int? total;
  final int? index;
  final WardrobeItemModel? item;
  final String? error;

  const WardrobeTaskSSEPayload({
    this.taskId,
    this.itemId,
    required this.status,
    this.total,
    this.index,
    this.item,
    this.error,
  });

  factory WardrobeTaskSSEPayload.fromJson(Map<String, dynamic> json) {
    WardrobeItemModel? parsedItem;
    if (json['data'] != null && json['data'] is Map<String, dynamic>) {
      parsedItem = WardrobeItemModel.fromJson(json['data']);
    } else if (json['item'] != null && json['item'] is Map<String, dynamic>) {
      parsedItem = WardrobeItemModel.fromJson(json['item']);
    }

    return WardrobeTaskSSEPayload(
      taskId: json['taskId']?.toString() ?? json['task_id']?.toString(),
      itemId: json['itemId']?.toString() ?? json['item_id']?.toString() ?? parsedItem?.id,
      status: json['status']?.toString().toLowerCase() ?? 'processing',
      total: json['total'] is int ? json['total'] : null,
      index: json['index'] is int ? json['index'] : null,
      item: parsedItem,
      error: json['error']?.toString() ?? json['message']?.toString(),
    );
  }
}

class UploadSignatureModel {
  final String apiKey;
  final String folder;
  final String? publicId;
  final String signature;
  final int timestamp;

  const UploadSignatureModel({
    required this.apiKey,
    required this.folder,
    this.publicId,
    required this.signature,
    required this.timestamp,
  });

  factory UploadSignatureModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] : json;
    return UploadSignatureModel(
      apiKey: data['apiKey'] ?? data['api_key'] ?? '',
      folder: data['folder'] ?? '',
      publicId: data['publicId'] ?? data['public_id'],
      signature: data['signature'] ?? '',
      timestamp: data['timestamp'] is int
          ? data['timestamp']
          : int.tryParse(data['timestamp']?.toString() ?? '0') ?? 0,
    );
  }
}

class BatchUploadItemRequest {
  final String? categoryId;
  final String imagePublicId;
  final String imageUrl;

  const BatchUploadItemRequest({
    this.categoryId,
    required this.imagePublicId,
    required this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
        if (categoryId != null && categoryId!.isNotEmpty) 'categoryId': categoryId,
        'imagePublicId': imagePublicId,
        'imageUrl': imageUrl,
      };
}

class UnderutilizedItemModel {
  final String itemId;
  final String name;
  final String categoryName;
  final double purchasePriceVnd;
  final int lastWornDaysAgo;
  final String imageUrl;

  const UnderutilizedItemModel({
    required this.itemId,
    required this.name,
    required this.categoryName,
    required this.purchasePriceVnd,
    required this.lastWornDaysAgo,
    required this.imageUrl,
  });

  String get formattedPrice {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    return formatter.format(purchasePriceVnd);
  }

  factory UnderutilizedItemModel.fromJson(Map<String, dynamic> json) {
    return UnderutilizedItemModel(
      itemId: json['itemId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Món đồ',
      categoryName: json['categoryName']?.toString() ?? 'Trang phục',
      purchasePriceVnd: (json['purchasePriceVnd'] as num?)?.toDouble() ?? 0.0,
      lastWornDaysAgo: json['lastWornDaysAgo'] is int ? json['lastWornDaysAgo'] : 0,
      imageUrl: json['imageUrl']?.toString() ?? '',
    );
  }
}

class WardrobeInsightsModel {
  final int totalItems;
  final double totalWardrobeValueVnd;
  final int underutilizedItemsCount;
  final List<UnderutilizedItemModel> underutilizedItems;
  final int expiringVouchersCount;

  const WardrobeInsightsModel({
    required this.totalItems,
    required this.totalWardrobeValueVnd,
    required this.underutilizedItemsCount,
    this.underutilizedItems = const [],
    this.expiringVouchersCount = 0,
  });

  String get formattedTotalValue {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    return formatter.format(totalWardrobeValueVnd);
  }

  factory WardrobeInsightsModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] : json;
    final list = (data['underutilizedItems'] as List<dynamic>?) ?? [];
    return WardrobeInsightsModel(
      totalItems: data['totalItems'] is int ? data['totalItems'] : 0,
      totalWardrobeValueVnd: (data['totalWardrobeValueVnd'] as num?)?.toDouble() ?? 0.0,
      underutilizedItemsCount: data['underutilizedItemsCount'] is int ? data['underutilizedItemsCount'] : 0,
      underutilizedItems: list.map((e) => UnderutilizedItemModel.fromJson(e as Map<String, dynamic>)).toList(),
      expiringVouchersCount: data['expiringVouchersCount'] is int ? data['expiringVouchersCount'] : 0,
    );
  }
}

class CategoryDistributionModel {
  final String categoryId;
  final String categoryName;
  final int itemCount;
  final double percentage;

  const CategoryDistributionModel({
    required this.categoryId,
    required this.categoryName,
    required this.itemCount,
    required this.percentage,
  });

  factory CategoryDistributionModel.fromJson(Map<String, dynamic> json) {
    return CategoryDistributionModel(
      categoryId: json['categoryId']?.toString() ?? '',
      categoryName: json['categoryName']?.toString() ?? 'Khác',
      itemCount: json['itemCount'] is int ? json['itemCount'] : 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class WardrobeCategoryDistributionResult {
  final int totalItems;
  final List<CategoryDistributionModel> categories;

  const WardrobeCategoryDistributionResult({
    required this.totalItems,
    this.categories = const [],
  });

  factory WardrobeCategoryDistributionResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] : json;
    final list = (data['categories'] as List<dynamic>?) ?? [];
    return WardrobeCategoryDistributionResult(
      totalItems: data['totalItems'] is int ? data['totalItems'] : 0,
      categories: list.map((e) => CategoryDistributionModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

/// Số tổng quan tủ đồ + outfit (US 006).
/// `GET /me/wardrobe-items/stats` — nguồn chuẩn cho Home (thay vì đếm list).
class WardrobeStats {
  final int activeItemsCount;
  final int outfitsCount;

  const WardrobeStats({
    this.activeItemsCount = 0,
    this.outfitsCount = 0,
  });

  factory WardrobeStats.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic> ? json['data'] : json;
    int asInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    return WardrobeStats(
      activeItemsCount: asInt(data['activeItemsCount']),
      outfitsCount: asInt(data['outfitsCount']),
    );
  }
}
