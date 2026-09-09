import 'package:intl/intl.dart';

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

class OutfitRecommendationItem {
  final String id;
  final String title;
  final String? brand;
  final String? category;
  final String? imageUrl;
  final String? color;
  final double? price;

  const OutfitRecommendationItem({
    required this.id,
    required this.title,
    this.brand,
    this.category,
    this.imageUrl,
    this.color,
    this.price,
  });

  factory OutfitRecommendationItem.fromJson(Map<String, dynamic> json) {
    return OutfitRecommendationItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? json['name'] ?? '',
      brand: json['brand'] ?? json['brandName'],
      category: json['category'] is Map ? json['category']['name'] : json['category']?.toString(),
      imageUrl: json['imageUrl'] ?? json['image_url'],
      color: json['color'],
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
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

  const OutfitRecommendationModel({
    required this.id,
    required this.title,
    this.occasion,
    this.explanation,
    this.weatherContext,
    this.tags = const [],
    this.items = const [],
  });

  factory OutfitRecommendationModel.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final rawTags = json['tags'] as List<dynamic>? ?? [];

    return OutfitRecommendationModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Gợi ý trang phục Closy',
      occasion: json['occasion'],
      explanation: json['explanation'] ?? json['stylingAdvice'],
      weatherContext: json['weatherContext'],
      tags: rawTags.map((t) => t.toString()).toList(),
      items: rawItems.map((i) => OutfitRecommendationItem.fromJson(i as Map<String, dynamic>)).toList(),
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

    OutfitRecommendationModel? rec;
    if (json['outfitRecommendation'] != null && json['outfitRecommendation'] is Map<String, dynamic>) {
      rec = OutfitRecommendationModel.fromJson(json['outfitRecommendation']);
    }

    final rawItems = json['suggestedItems'] as List<dynamic>? ?? [];

    return ChatMessageModel(
      id: json['id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      sender: json['sender']?.toString().toUpperCase() ?? 'ASSISTANT',
      timestamp: time,
      outfitRecommendation: rec,
      suggestedItems: rawItems.map((e) => OutfitRecommendationItem.fromJson(e as Map<String, dynamic>)).toList(),
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
