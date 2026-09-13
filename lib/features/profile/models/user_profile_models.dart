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

/// Loại giao dịch PayOS mà màn hình chờ đang theo dõi.
enum PaymentKind {
  /// Nạp tiền vào ví — success khi số dư ví tăng đủ số tiền.
  walletTopUp,

  /// Mua gói trực tiếp — success khi subscription thành Premium.
  directPurchase,
}

/// Gói thông tin mà caller PHẢI truyền cho PaymentWaitingScreen.
/// Khắc phục lỗi hardcode số tiền / tên gói ở màn hình chờ cũ.
class PendingPayment {
  /// Mã đơn duy nhất từ backend.
  final int orderCode;

  /// Checkout URL PayOS.
  final String paymentUrl;

  /// Số tiền đúng của giao dịch (không dùng fallback).
  final double amount;

  /// Loại giao dịch — quyết định poll ví hay poll subscription.
  final PaymentKind kind;

  /// Nhãn hiển thị: topup dùng mặc định, mua gói dùng tên gói.
  final String label;

  /// Snapshot số dư ví ngay trước khi tạo link (chỉ dùng cho nạp ví).
  final double baselineBalance;

  /// Thời điểm tạo link — dùng để tính hết hạn 15 phút.
  final DateTime createdAt;

  const PendingPayment({
    required this.orderCode,
    required this.paymentUrl,
    required this.amount,
    required this.kind,
    required this.label,
    this.baselineBalance = 0,
    required this.createdAt,
  });

  /// Dựng từ link nạp ví vừa tạo.
  factory PendingPayment.topUp({
    required PaymentLinkModel link,
    required double amount,
    required double baselineBalance,
  }) {
    return PendingPayment(
      orderCode: link.orderCode,
      paymentUrl: link.paymentUrl,
      amount: amount,
      kind: PaymentKind.walletTopUp,
      label: 'Nạp ví Closy Pay',
      baselineBalance: baselineBalance,
      createdAt: DateTime.now(),
    );
  }

  /// Dựng từ link mua gói trực tiếp vừa tạo.
  factory PendingPayment.purchase({
    required PaymentLinkModel link,
    required double amount,
    required String planLabel,
  }) {
    return PendingPayment(
      orderCode: link.orderCode,
      paymentUrl: link.paymentUrl,
      amount: amount,
      kind: PaymentKind.directPurchase,
      label: planLabel,
      createdAt: DateTime.now(),
    );
  }

  bool get isTopUp => kind == PaymentKind.walletTopUp;

  /// Mã PayOS hết hiệu lực sau 15 phút nếu chưa thanh toán.
  bool get isExpired =>
      DateTime.now().difference(createdAt).inSeconds >= 900;

  String get formattedAmount {
    final intAmt = amount.toInt();
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
}


/// Trạng thái kết quả thanh toán hiển thị trên trang thông báo.
enum PaymentResultStatus {
  success,
  failed,
  cancelled,
  expired,
}

/// Kết quả thanh toán để điều hướng về trang thông báo.
///
/// Deep-link / web returnUrl chỉ mang [orderCode]/[status] để điều hướng;
/// trạng thái thật luôn verify lại qua backend (ví / subscription).
class PaymentResult {
  final int orderCode;
  final double amount;
  final PaymentKind kind;
  final String label;
  final PaymentResultStatus status;
  final String? message;
  final String? paymentUrl;

  const PaymentResult({
    required this.orderCode,
    required this.amount,
    required this.kind,
    required this.label,
    required this.status,
    this.message,
    this.paymentUrl,
  });

  bool get isTopUp => kind == PaymentKind.walletTopUp;
  bool get isSuccess => status == PaymentResultStatus.success;

  String get formattedAmount {
    final intAmt = amount.toInt();
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

  factory PaymentResult.fromPending(
    PendingPayment pending,
    PaymentResultStatus status, {
    String? message,
  }) {
    return PaymentResult(
      orderCode: pending.orderCode,
      amount: pending.amount,
      kind: pending.kind,
      label: pending.label,
      status: status,
      message: message,
      paymentUrl: pending.paymentUrl,
    );
  }

  /// Parse từ query deep-link / web: ?status=&orderCode=&amount=&kind=
  ///
  /// PayOS khi redirect về returnUrl/cancelUrl sẽ append thêm param của nó
  /// (`code=00&id=...&cancel=false&status=PAID&orderCode=...`) nên phải ưu
  /// tiên đọc param PayOS trước, param `status` của mình chỉ là fallback.
  factory PaymentResult.fromQuery(Map<String, String> q) {
    final payosCancel = (q['cancel'] ?? '').toLowerCase() == 'true';
    final payosStatus = (q['status'] ?? '').toUpperCase();
    final payosCode = q['code'] ?? '';
    // PayOS cancelUrl cũng có thể mang status=CANCELLED.
    final payosCancelled = payosStatus == 'CANCELLED';

    late final PaymentResultStatus status;
    if (payosCancel || payosCancelled) {
      status = PaymentResultStatus.cancelled;
    } else if (payosStatus == 'PAID' || payosCode == '00') {
      status = PaymentResultStatus.success;
    } else {
      final statusStr = (q['result'] ?? q['status'] ?? 'success').toLowerCase();
      status = switch (statusStr) {
        'success' || 'paid' => PaymentResultStatus.success,
        'failed' || 'fail' || 'error' => PaymentResultStatus.failed,
        'cancelled' || 'cancel' || 'canceled' => PaymentResultStatus.cancelled,
        'expired' => PaymentResultStatus.expired,
        // PayOS status khác (PENDING/PROCESSING...): chưa chốt được.
        _ => PaymentResultStatus.failed,
      };
    }
    final kindStr = (q['kind'] ?? 'topup').toLowerCase();
    final kind = (kindStr.contains('purchase') || kindStr.contains('sub'))
        ? PaymentKind.directPurchase
        : PaymentKind.walletTopUp;
    return PaymentResult(
      orderCode: int.tryParse(q['orderCode'] ?? q['ordercode'] ?? '0') ?? 0,
      amount: double.tryParse(q['amount'] ?? '0') ?? 0,
      kind: kind,
      label: q['label'] ??
          (kind == PaymentKind.walletTopUp
              ? 'Nạp ví Closy Pay'
              : 'Gói Closy Premium'),
      status: status,
      message: q['message'],
      paymentUrl: q['paymentUrl'],
    );
  }

  Map<String, String> toQuery() => {
        'status': status.name,
        'orderCode': orderCode.toString(),
        'amount': amount.toStringAsFixed(0),
        'kind': isTopUp ? 'topup' : 'purchase',
        'label': label,
      };
}

/// Helper dựng returnUrl/cancelUrl cho PayOS.
///
/// - Mobile: custom scheme `smartwardrobe://...` (cần intent-filter + app_links).
/// - Web: `${origin}/profile/payment/result?...` để land đúng trang thông báo.
class PaymentReturnUrls {
  final String returnUrl;
  final String cancelUrl;

  const PaymentReturnUrls({required this.returnUrl, required this.cancelUrl});

  static PaymentReturnUrls forTopUp({
    required bool isWeb,
    String? webOrigin,
    double? amount,
  }) {
    if (isWeb) {
      final origin = (webOrigin ?? '').replaceAll(RegExp(r'/$'), '');
      final amt = (amount ?? 0).toStringAsFixed(0);
      return PaymentReturnUrls(
        returnUrl:
            '$origin/profile/payment/result?result=success&kind=topup&amount=$amt',
        cancelUrl:
            '$origin/profile/payment/result?result=cancelled&kind=topup&amount=$amt',
      );
    }
    return const PaymentReturnUrls(
      returnUrl: 'smartwardrobe://wallet/topup/success',
      cancelUrl: 'smartwardrobe://wallet/topup/cancel',
    );
  }

  static PaymentReturnUrls forPurchase({
    required bool isWeb,
    String? webOrigin,
    double? amount,
  }) {
    if (isWeb) {
      final origin = (webOrigin ?? '').replaceAll(RegExp(r'/$'), '');
      final amt = (amount ?? 0).toStringAsFixed(0);
      return PaymentReturnUrls(
        returnUrl:
            '$origin/profile/payment/result?result=success&kind=purchase&amount=$amt',
        cancelUrl:
            '$origin/profile/payment/result?result=cancelled&kind=purchase&amount=$amt',
      );
    }
    return const PaymentReturnUrls(
      returnUrl: 'smartwardrobe://subscription/success',
      cancelUrl: 'smartwardrobe://subscription/cancel',
    );
  }
}


class WalletModel {
  final String userId;
  final double balance;
  final String currency;
  final DateTime? updatedAt;

  const WalletModel({
    this.userId = '',
    this.balance = 0.0,
    this.currency = 'VND',
    this.updatedAt,
  });

  String get formattedBalance {
    final b = balance.toInt();
    final formatted = b.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    return '$formatted đ';
  }

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    final rawBalance = json['balance'] ?? json['Balance'] ?? 0;
    final bal = (rawBalance is num) ? rawBalance.toDouble() : double.tryParse(rawBalance.toString()) ?? 0.0;

    DateTime? updated;
    final rawUpdated = json['updatedAt'] ?? json['UpdatedAt'];
    if (rawUpdated != null) {
      updated = DateTime.tryParse(rawUpdated.toString());
    }

    return WalletModel(
      userId: json['userID']?.toString() ?? json['userId']?.toString() ?? json['UserID']?.toString() ?? '',
      balance: bal,
      currency: json['currency']?.toString() ?? json['Currency']?.toString() ?? 'VND',
      updatedAt: updated,
    );
  }
}

class WalletStatementModel {
  final String id;
  final double amount;
  final String transactionType;
  final double previousBalance;
  final double newBalance;
  final String description;
  final DateTime? createdAt;

  const WalletStatementModel({
    required this.id,
    required this.amount,
    required this.transactionType,
    required this.previousBalance,
    required this.newBalance,
    this.description = '',
    this.createdAt,
  });

  bool get isIncome =>
      amount > 0 ||
      transactionType.toLowerCase().contains('topup') ||
      transactionType.toLowerCase().contains('credit') ||
      transactionType.toLowerCase().contains('deposit');

  String get formattedAmount {
    final absAmount = amount.abs().toInt();
    final formatted = absAmount.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
    final sign = isIncome ? '+' : '-';
    return '$sign$formatted đ';
  }

  String get typeLabel {
    final t = transactionType.toLowerCase();
    if (t.contains('topup') || t.contains('deposit')) return 'Nạp tiền vào ví';
    if (t.contains('purchase')) return 'Mua gói hội viên';
    if (t.contains('refund') || t.contains('credit')) return 'Hoàn tiền vào ví';
    return 'Giao dịch ví';
  }

  factory WalletStatementModel.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'] ?? json['Amount'] ?? 0;
    final amt = (rawAmount is num) ? rawAmount.toDouble() : double.tryParse(rawAmount.toString()) ?? 0.0;

    final rawPrev = json['previousBalance'] ?? json['PreviousBalance'] ?? 0;
    final prev = (rawPrev is num) ? rawPrev.toDouble() : double.tryParse(rawPrev.toString()) ?? 0.0;

    final rawNew = json['newBalance'] ?? json['NewBalance'] ?? 0;
    final newBal = (rawNew is num) ? rawNew.toDouble() : double.tryParse(rawNew.toString()) ?? 0.0;

    DateTime? created;
    final rawCreated = json['createdAt'] ?? json['CreatedAt'];
    if (rawCreated != null) {
      created = DateTime.tryParse(rawCreated.toString());
    }

    return WalletStatementModel(
      id: json['id']?.toString() ?? json['ID']?.toString() ?? '',
      amount: amt,
      transactionType: json['transactionType']?.toString() ?? json['TransactionType']?.toString() ?? '',
      previousBalance: prev,
      newBalance: newBal,
      description: json['description']?.toString() ?? json['Description']?.toString() ?? '',
      createdAt: created,
    );
  }
}
