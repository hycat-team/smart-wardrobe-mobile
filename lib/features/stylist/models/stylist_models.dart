import 'package:intl/intl.dart';

import '../../outfit_studio/models/outfit_models.dart';

class ChatSessionModel {
  final String id;
  final String title;
  final String? contextSummary;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ChatSessionModel({
    required this.id,
    required this.title,
    this.contextSummary,
    this.isArchived = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory ChatSessionModel.fromJson(Map<String, dynamic> json) {
    DateTime created;
    try {
      created = DateTime.parse(json['createdAt']?.toString() ?? DateTime.now().toIso8601String());
    } catch (_) {
      created = DateTime.now();
    }

    DateTime? updated;
    if (json['updatedAt'] != null) {
      try {
        updated = DateTime.parse(json['updatedAt'].toString());
      } catch (_) {}
    }

    return ChatSessionModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Cuộc trò chuyện mới',
      contextSummary: json['contextSummary']?.toString(),
      isArchived: json['isArchived'] == true,
      createdAt: created,
      updatedAt: updated,
    );
  }

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inDays == 0) {
      return 'Hôm nay, ${DateFormat('HH:mm').format(createdAt)}';
    } else if (diff.inDays == 1) {
      return 'Hôm qua';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} ngày trước';
    } else {
      return DateFormat('dd/MM/yyyy').format(createdAt);
    }
  }
}

/// Một món đồ trong thẻ gợi ý của stylist.
///
/// Spec 015 — FR-034: đây là mô hình **duy nhất** mang kết quả gợi ý tới màn
/// trò chuyện. Không tạo bộ model phẳng thứ hai song song (chính cái trùng lặp đó
/// đã khiến ảnh gợi ý ra rỗng).
class OutfitRecommendationItem {
  final String id;
  final String title;
  final String? brand;
  final String? category;
  final String? imageUrl;
  final String? color;
  final double? price;

  /// FR-020/FR-031/FR-032 — vai trò nguyên chuỗi máy chủ trả về.
  ///
  /// FR-033: trường mới **phải có giá trị mặc định** (hiến pháp II).
  final String? role;

  /// Món thay thế (không phải món chính của nhóm vai trò).
  final bool isAlternative;

  const OutfitRecommendationItem({
    required this.id,
    required this.title,
    this.brand,
    this.category,
    this.imageUrl,
    this.color,
    this.price,
    this.role,
    this.isAlternative = false,
  });

  /// FR-031/FR-032 — nhãn vai trò tiếng Việt.
  ///
  /// Là **getter** gọi tới bảng ánh xạ đóng dùng chung, không phải một bảng riêng —
  /// tránh sinh ra nguồn nhãn thứ hai (FR-034).
  String get roleLabelVi =>
      role == null ? '' : outfitRoleLabelVi(role!);

  /// Món không có ảnh thì hiện nhãn vai trò thay vì khung trống (FR-019).
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;

  factory OutfitRecommendationItem.fromJson(Map<String, dynamic> json) {
    return OutfitRecommendationItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['name'] ?? '',
      brand: json['brand'] ?? json['brandName'],
      category: json['category'] is Map ? json['category']['name'] : json['category']?.toString(),
      imageUrl: json['imageUrl'] ?? json['image_url'],
      color: json['color'],
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      role: json['role']?.toString(),
      isAlternative: json['isAlternative'] == true,
    );
  }
}

class OutfitRecommendationModel {
  final String id;
  final String title;
  final String? occasion;
  final String? explanation;
  final String? weatherContext;
  final List<String> tags;
  final List<OutfitRecommendationItem> items;

  /// FR-029 — máy chủ tự sinh bộ gợi ý này (thường khi **hết hạn mức**).
  /// Phải gắn nhãn dự phòng, không trình bày như gợi ý chuẩn của stylist.
  ///
  /// FR-033: trường mới **phải có giá trị mặc định** (hiến pháp II).
  final bool isFallback;

  /// FR-030 — số hạn mức còn lại. Máy chủ KHÔNG trả mốc thời gian làm mới
  /// (`RemainingQuota` là con số đơn lẻ), nên ứng dụng chỉ hiện con số này kèm
  /// thông báo chung "làm mới vào ngày mới" — không được bịa ngày giờ cụ thể.
  final int remainingQuota;

  const OutfitRecommendationModel({
    required this.id,
    required this.title,
    this.occasion,
    this.explanation,
    this.weatherContext,
    this.tags = const [],
    this.items = const [],
    this.isFallback = false,
    this.remainingQuota = 0,
  });

  factory OutfitRecommendationModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final rawTags = json['tags'] as List<dynamic>? ?? [];

    // Spec 015 — T052 (FR-033): trước đây factory bỏ sót hai trường này, nên khi
    // parse lại từ JSON chúng rơi về default `false`/`0` — cờ dự phòng biến mất
    // và UI hiển thị bộ gợi ý dự phòng y như gợi ý chuẩn, trái FR-029.
    //
    // Đọc CẢ `fallback` (tên trường máy chủ gửi, `dto/recommendation.go`) lẫn
    // `isFallback` (khoá cũ của ứng dụng), đồng thời chấp nhận `remainingQuota`
    // dạng số lẫn chuỗi — máy chủ có thể trả 0..3 dạng `json.Number`.
    int parseQuota(dynamic raw) {
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      return int.tryParse(raw?.toString() ?? '') ?? 0;
    }

    final rawFallback = json['fallback'] ?? json['isFallback'];

    return OutfitRecommendationModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Gợi ý trang phục Closy',
      occasion: json['occasion'],
      explanation: json['explanation'] ?? json['stylingAdvice'],
      weatherContext: json['weatherContext'],
      tags: rawTags.map((t) => t.toString()).toList(),
      items: rawItems.map((i) => OutfitRecommendationItem.fromJson(i as Map<String, dynamic>)).toList(),
      isFallback: rawFallback == true ||
          (rawFallback is String && rawFallback.toLowerCase() == 'true'),
      remainingQuota: parseQuota(json['remainingQuota']),
    );
  }
}

class ChatMessageModel {
  final String id;
  final String content;
  final String sender; // 'USER' | 'ASSISTANT' | 'SYSTEM'
  final DateTime timestamp;
  final bool isStreaming;
  final OutfitRecommendationModel? outfitRecommendation;
  final List<OutfitRecommendationItem> suggestedItems;

  const ChatMessageModel({
    required this.id,
    required this.content,
    required this.sender,
    required this.timestamp,
    this.isStreaming = false,
    this.outfitRecommendation,
    this.suggestedItems = const [],
  });

  bool get isUser => sender.toUpperCase() == 'USER';
  bool get hasOutfitRedirect => content.contains('[ACTION:REDIRECT_OUTFIT]');

  String get cleanContent {
    return content.replaceAll('[ACTION:REDIRECT_OUTFIT]', '').trim();
  }

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    DateTime time;
    try {
      time = DateTime.parse(json['createdAt']?.toString() ?? DateTime.now().toIso8601String());
    } catch (_) {
      time = DateTime.now();
    }

    // Spec 015 — T038 (nghiên cứu R8): `ChatMessageRes` của máy chủ **không** gửi
    // `outfitRecommendation` lẫn `suggestedItems`. Trước đây `fromJson` vẫn đọc
    // hai trường đó, nhưng chúng luôn `null`/rỗng — dấu hiệu cho thấy tác giả
    // tưởng lịch sử có thể khôi phục lại thẻ gợi ý.
    //
    // Thực tế thẻ gợi ý chỉ tồn tại trong RAM của phiên đang mở: máy chủ lưu văn
    // bản trò chuyện, không lưu bộ gợi ý. Vì vậy hai trường giữ nguyên giá trị
    // mặc định và KHÔNG đọc từ JSON.
    //
    // `outfitRecommendation`/`suggestedItems` vẫn được `copyWith` giữ nguyên nên
    // luồng trong phiên hiện tại không bị ảnh hưởng.
    return ChatMessageModel(
      id: json['id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      sender: json['sender']?.toString().toUpperCase() ?? 'ASSISTANT',
      timestamp: time,
    );
  }

  ChatMessageModel copyWith({
    String? id,
    String? content,
    String? sender,
    DateTime? timestamp,
    bool? isStreaming,
    OutfitRecommendationModel? outfitRecommendation,
    List<OutfitRecommendationItem>? suggestedItems,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      content: content ?? this.content,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
      outfitRecommendation: outfitRecommendation ?? this.outfitRecommendation,
      suggestedItems: suggestedItems ?? this.suggestedItems,
    );
  }
}
