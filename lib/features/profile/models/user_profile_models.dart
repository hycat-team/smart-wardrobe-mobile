class UpdateProfileRequest {
  final String firstName;
  final String? lastName;
  final String? dateOfBirth; // YYYY-MM-DD
  final int? gender; // 1: MALE, 2: FEMALE, 3: OTHER, 0: UNKNOWN
  final String? address;

  const UpdateProfileRequest({
    required this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.gender,
    this.address,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'firstName': firstName,
    };
    if (lastName != null && lastName!.trim().isNotEmpty) {
      map['lastName'] = lastName!.trim();
    }
    if (dateOfBirth != null && dateOfBirth!.trim().isNotEmpty) {
      map['dateOfBirth'] = dateOfBirth!.trim();
    }
    if (gender != null) {
      map['gender'] = gender;
    }
    if (address != null && address!.trim().isNotEmpty) {
      map['address'] = address!.trim();
    }
    return map;
  }
}

class ChangePasswordRequest {
  final String oldPassword;
  final String newPassword;
  final String confirmPassword;
  final bool logoutAllDevices;

  const ChangePasswordRequest({
    required this.oldPassword,
    required this.newPassword,
    required this.confirmPassword,
    this.logoutAllDevices = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'oldPassword': oldPassword,
      'newPassword': newPassword,
      'confirmPassword': confirmPassword,
      'logoutAllDevices': logoutAllDevices,
    };
  }
}

class AvatarSignatureModel {
  final String signature;
  final int timestamp;
  final String folder;
  final String apiKey;
  final String? publicId;

  const AvatarSignatureModel({
    required this.signature,
    required this.timestamp,
    required this.folder,
    required this.apiKey,
    this.publicId,
  });

  factory AvatarSignatureModel.fromJson(Map<String, dynamic> json) {
    return AvatarSignatureModel(
      signature: json['signature']?.toString() ?? '',
      timestamp: json['timestamp'] is int
          ? json['timestamp']
          : int.tryParse(json['timestamp']?.toString() ?? '0') ?? 0,
      folder: json['folder']?.toString() ?? 'avatars',
      apiKey: json['apiKey']?.toString() ?? '',
      publicId: json['publicId']?.toString(),
    );
  }
}

class UserSubscriptionModel {
  final String planId;
  final String planName;
  final String planSlug;
  final String? expiresAt;
  final bool isAutoRenewEnabled;
  final int maxWardrobeItems;
  final int maxOutfits;
  final int aiOutfitDailyQuota;
  final int aiChatDailyQuota;
  final String status;

  const UserSubscriptionModel({
    this.planId = '',
    this.planName = 'Miễn Phí',
    this.planSlug = 'free',
    this.expiresAt,
    this.isAutoRenewEnabled = false,
    this.maxWardrobeItems = 100,
    this.maxOutfits = 100,
    this.aiOutfitDailyQuota = 5,
    this.aiChatDailyQuota = 3,
    this.status = 'ACTIVE',
  });

  bool get isPremium =>
      planSlug.toLowerCase() != 'free' &&
      planSlug.isNotEmpty &&
      status.toUpperCase() == 'ACTIVE';

  factory UserSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return UserSubscriptionModel(
      planId: json['planId']?.toString() ?? json['PlanID']?.toString() ?? json['id']?.toString() ?? '',
      planName: json['planName']?.toString() ?? json['PlanName']?.toString() ?? 'Miễn Phí',
      planSlug: json['planSlug']?.toString() ?? json['PlanSlug']?.toString() ?? 'free',
      expiresAt: json['expiresAt']?.toString() ?? json['ExpiresAt']?.toString(),
      isAutoRenewEnabled: json['isAutoRenewEnabled'] == true || json['IsAutoRenewEnabled'] == true,
      maxWardrobeItems: json['maxWardrobeItems'] as int? ?? json['MaxWardrobeItems'] as int? ?? 100,
      maxOutfits: json['maxOutfits'] as int? ?? json['MaxOutfits'] as int? ?? 100,
      aiOutfitDailyQuota: json['aiOutfitDailyQuota'] as int? ?? json['AiOutfitDailyQuota'] as int? ?? 5,
      aiChatDailyQuota: json['aiChatDailyQuota'] as int? ?? json['AiChatDailyQuota'] as int? ?? 3,
      status: json['status']?.toString() ?? 'ACTIVE',
    );
  }
}

class DailyQuotaModel {
  final int aiChatUsed;
  final int aiChatLimit;
  final int aiOutfitUsed;
  final int aiOutfitLimit;
  final String? lastResetDate;

  const DailyQuotaModel({
    this.aiChatUsed = 0,
    this.aiChatLimit = 3,
    this.aiOutfitUsed = 0,
    this.aiOutfitLimit = 5,
    this.lastResetDate,
  });

  double get chatProgress => aiChatLimit > 0 ? (aiChatUsed / aiChatLimit).clamp(0.0, 1.0) : 0.0;
  double get outfitProgress => aiOutfitLimit > 0 ? (aiOutfitUsed / aiOutfitLimit).clamp(0.0, 1.0) : 0.0;

  int get chatRemaining => (aiChatLimit - aiChatUsed).clamp(0, aiChatLimit);
  int get outfitRemaining => (aiOutfitLimit - aiOutfitUsed).clamp(0, aiOutfitLimit);

  factory DailyQuotaModel.fromJson(Map<String, dynamic> json) {
    return DailyQuotaModel(
      aiChatUsed: json['aiUsageCount'] as int? ?? json['AiUsageCount'] as int? ?? json['aiChatUsed'] as int? ?? 0,
      aiChatLimit: json['aiChatDailyQuota'] as int? ?? json['AiChatDailyQuota'] as int? ?? json['aiChatLimit'] as int? ?? 3,
      aiOutfitUsed: json['outfitRecommendCount'] as int? ?? json['OutfitRecommendCount'] as int? ?? json['aiOutfitUsed'] as int? ?? 0,
      aiOutfitLimit: json['aiOutfitDailyQuota'] as int? ?? json['AiOutfitDailyQuota'] as int? ?? json['aiOutfitLimit'] as int? ?? 5,
      lastResetDate: json['lastResetDate']?.toString() ?? json['LastResetDate']?.toString(),
    );
  }
}

class SubscriptionPlanModel {
  final String id;
  final String name;
  final String slug;
  final String? description;
  final num price;
  final int durationDays;
  final int maxWardrobeItems;
  final int maxOutfits;
  final int aiOutfitDailyQuota;
  final int aiChatDailyQuota;
  final List<String> features;
  final bool isActive;

  const SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.price,
    this.durationDays = 30,
    this.maxWardrobeItems = 100,
    this.maxOutfits = 100,
    this.aiOutfitDailyQuota = 5,
    this.aiChatDailyQuota = 3,
    this.features = const [],
    this.isActive = true,
  });

  String get formattedPrice {
    if (price == 0) return 'Miễn phí';
    final p = price.toInt();
    final formatted = p.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    return '$formatted đ';
  }

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    final rawFeatures = json['features'];
    List<String> featureList = [];
    if (rawFeatures is List && rawFeatures.isNotEmpty) {
      featureList = rawFeatures.map((f) => f.toString()).toList();
    } else {
      final items = json['maxWardrobeItems'] as int? ?? json['MaxWardrobeItems'] as int? ?? 100;
      final outfits = json['maxOutfits'] as int? ?? json['MaxOutfits'] as int? ?? 100;
      final aiOutfit = json['aiOutfitDailyQuota'] as int? ?? json['AiOutfitDailyQuota'] as int? ?? 5;
      final aiChat = json['aiChatDailyQuota'] as int? ?? json['AiChatDailyQuota'] as int? ?? 3;
      final slugStr = json['slug']?.toString() ?? json['Slug']?.toString() ?? '';

      if (slugStr == 'premium-monthly') {
        featureList = [
          'Quản lý đến $items món đồ tủ đồ cá nhân',
          'Lưu trữ đến $outfits set trang phục phong cách',
          '$aiOutfit lượt gợi ý phối đồ AI thông minh / ngày',
          '$aiChat lượt trò chuyện Stylist AI riêng biệt / ngày',
          'Trải nghiệm không quảng cáo & ưu tiên xử lý AI',
          'Đồng bộ hóa đám mây đa thiết bị tức thì',
        ];
      } else {
        featureList = [
          'Tủ đồ cơ bản tối đa $items món đồ',
          'Lưu tối đa $outfits set đồ phong cách',
          '$aiOutfit lượt phối đồ AI tự động / ngày',
          '$aiChat lượt tư vấn Stylist AI / ngày',
        ];
      }
    }

    return SubscriptionPlanModel(
      id: json['id']?.toString() ?? json['ID']?.toString() ?? '',
      name: json['name']?.toString() ?? json['Name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? json['Slug']?.toString() ?? json['planSlug']?.toString() ?? '',
      description: json['description']?.toString() ?? json['Description']?.toString(),
      price: json['price'] as num? ?? json['Price'] as num? ?? 0,
      durationDays: json['durationDays'] as int? ?? json['DurationDays'] as int? ?? 30,
      maxWardrobeItems: json['maxWardrobeItems'] as int? ?? json['MaxWardrobeItems'] as int? ?? 100,
      maxOutfits: json['maxOutfits'] as int? ?? json['MaxOutfits'] as int? ?? 100,
      aiOutfitDailyQuota: json['aiOutfitDailyQuota'] as int? ?? json['AiOutfitDailyQuota'] as int? ?? 5,
      aiChatDailyQuota: json['aiChatDailyQuota'] as int? ?? json['AiChatDailyQuota'] as int? ?? 3,
      features: featureList,
      isActive: json['isActive'] != false && json['IsActive'] != false,
    );
  }
}

class PaymentLinkModel {
  final String paymentUrl;
  final int orderCode;
  final int paymentStatus;
  final String? expiresAt;
  final double? amount;

  const PaymentLinkModel({
    required this.paymentUrl,
    required this.orderCode,
    this.paymentStatus = 0,
    this.expiresAt,
    this.amount,
  });

  String get formattedAmount {
    if (amount == null || amount! <= 0) return '249.000 đ';
    final intAmt = amount!.toInt();
    final str = intAmt.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(str[i]);
    }
    return '${buffer.toString()} đ';
  }

  factory PaymentLinkModel.fromJson(Map<String, dynamic> json) {
    return PaymentLinkModel(
      paymentUrl: json['paymentUrl']?.toString() ?? '',
      orderCode: json['orderCode'] is num
          ? (json['orderCode'] as num).toInt()
          : int.tryParse(json['orderCode']?.toString() ?? '0') ?? 0,
      paymentStatus: json['paymentStatus'] is num
          ? (json['paymentStatus'] as num).toInt()
          : int.tryParse(json['paymentStatus']?.toString() ?? '0') ?? 0,
      expiresAt: json['expiresAt']?.toString(),
      amount: json['amount'] != null ? double.tryParse(json['amount'].toString()) : null,
    );
  }
}
