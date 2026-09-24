import 'package:intl/intl.dart';

/// Models cho màn Thống kê (spec 009).
///
/// Nguồn dữ liệu: gộp từ các endpoint dashboard hiện có
/// (`/me/dashboard/wardrobe-insights`,
/// `/me/dashboard/wardrobe/category-distribution`, `/me/outfits`).
/// Theo kết quả xác minh API (research.md T001), máy chủ chưa có
/// `wearCount`/`wearHistory` thật nên `wearDataAvailable` mặc định false
/// và các chỉ số phụ thuộc dữ liệu đó sẽ được ẩn kèm ghi chú (FR-014).

/// Mức độ sử dụng tủ đồ (nhóm chỉ số a).
class UtilizationMetric {
  final int totalItems;

  /// Số món `lastWornDaysAgo >= 30`. Lấy từ `underutilizedItemsCount`
  /// của máy chủ (ngữ nghĩa ">30 ngày" như màn insights hiện có).
  final int unused30;

  /// Đếm từ danh sách `underutilizedItems` trả về
  /// (`lastWornDaysAgo >= 60` / `>= 90`). Có thể thiếu nếu máy chủ
  /// cắt danh sách theo limit.
  final int unused60;
  final int unused90;

  const UtilizationMetric({
    this.totalItems = 0,
    this.unused30 = 0,
    this.unused60 = 0,
    this.unused90 = 0,
  });

  /// Tỷ lệ sử dụng, 0.0–1.0. `totalItems == 0` → 0.0 (không chia 0).
  double get utilizationRate {
    if (totalItems <= 0) return 0.0;
    return ((totalItems - unused30) / totalItems).clamp(0.0, 1.0);
  }

  String get formattedRate =>
      '${(utilizationRate * 100).toStringAsFixed(0)}%';

  factory UtilizationMetric.fromJson(Map<String, dynamic> json) {
    final data =
        json['data'] is Map<String, dynamic> ? json['data'] : json;
    return UtilizationMetric(
      totalItems: data['totalItems'] is int ? data['totalItems'] : 0,
      unused30: data['unused30'] is int ? data['unused30'] : 0,
      unused60: data['unused60'] is int ? data['unused60'] : 0,
      unused90: data['unused90'] is int ? data['unused90'] : 0,
    );
  }
}

/// Giá trị tủ đồ (nhóm chỉ số b, phần giá trị).
class ValueMetric {
  final double totalValueVnd;
  final List<CategoryValue> byCategory;

  /// Số món thiếu giá mua (chỉ để chú thích).
  final int missingPriceCount;

  const ValueMetric({
    this.totalValueVnd = 0.0,
    this.byCategory = const [],
    this.missingPriceCount = 0,
  });

  String get formattedTotalValue {
    final formatter =
        NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    return formatter.format(totalValueVnd);
  }

  factory ValueMetric.fromJson(Map<String, dynamic> json) {
    final data =
        json['data'] is Map<String, dynamic> ? json['data'] : json;
    final list = (data['byCategory'] as List<dynamic>?) ?? [];
    return ValueMetric(
      totalValueVnd:
          (data['totalValueVnd'] as num?)?.toDouble() ?? 0.0,
      byCategory: list
          .map((e) => CategoryValue.fromJson(e as Map<String, dynamic>))
          .toList(),
      missingPriceCount:
          data['missingPriceCount'] is int ? data['missingPriceCount'] : 0,
    );
  }
}

/// Giá trị theo danh mục. `valueVnd` null khi máy chủ chưa cung cấp
/// (endpoint phân bổ danh mục hiện chỉ có số lượng).
class CategoryValue {
  final String categoryId;
  final String categoryName;
  final int itemCount;
  final double? valueVnd;

  const CategoryValue({
    this.categoryId = '',
    this.categoryName = 'Khác',
    this.itemCount = 0,
    this.valueVnd,
  });

  factory CategoryValue.fromJson(Map<String, dynamic> json) {
    return CategoryValue(
      categoryId: json['categoryId']?.toString() ?? '',
      categoryName: json['categoryName']?.toString() ?? 'Khác',
      itemCount: json['itemCount'] is int ? json['itemCount'] : 0,
      valueVnd: (json['valueVnd'] as num?)?.toDouble(),
    );
  }
}

/// Chi phí mỗi lần mặc (nhóm chỉ số b, phần cost-per-wear).
/// `costPerWear` null khi `wearCount == 0` → hiển thị "Chưa mặc".
class CostPerWear {
  final String itemId;
  final String name;
  final double purchasePriceVnd;
  final int wearCount;

  const CostPerWear({
    this.itemId = '',
    this.name = 'Món đồ',
    this.purchasePriceVnd = 0.0,
    this.wearCount = 0,
  });

  double? get costPerWear =>
      wearCount <= 0 ? null : purchasePriceVnd / wearCount;

  bool get hasBeenWorn => wearCount > 0;

  String get formattedCostPerWear {
    final cpw = costPerWear;
    if (cpw == null) return 'Chưa mặc';
    final formatter =
        NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0);
    return formatter.format(cpw);
  }

  factory CostPerWear.fromJson(Map<String, dynamic> json) {
    return CostPerWear(
      itemId: json['itemId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Món đồ',
      purchasePriceVnd:
          (json['purchasePriceVnd'] as num?)?.toDouble() ?? 0.0,
      wearCount: json['wearCount'] is int ? json['wearCount'] : 0,
    );
  }
}

/// Thống kê outfit (nhóm chỉ số c). `usedOutfits` null khi máy chủ
/// chưa cung cấp dữ liệu "đã dùng" — chỉ hiển thị outfit đã lưu.
class OutfitStat {
  final int totalOutfits;
  final int? usedOutfits;

  const OutfitStat({this.totalOutfits = 0, this.usedOutfits});

  factory OutfitStat.fromJson(Map<String, dynamic> json) {
    final data =
        json['data'] is Map<String, dynamic> ? json['data'] : json;
    return OutfitStat(
      totalOutfits:
          data['totalOutfits'] is int ? data['totalOutfits'] : 0,
      usedOutfits:
          data['usedOutfits'] is int ? data['usedOutfits'] : null,
    );
  }
}

/// Điểm xu hướng theo tháng (nhóm chỉ số d). `month` định dạng `YYYY-MM`.
class TimeTrendPoint {
  final String month;
  final int wearCount;

  const TimeTrendPoint({this.month = '', this.wearCount = 0});

  factory TimeTrendPoint.fromJson(Map<String, dynamic> json) {
    return TimeTrendPoint(
      month: json['month']?.toString() ?? '',
      wearCount: json['wearCount'] is int ? json['wearCount'] : 0,
    );
  }
}

/// Gói dữ liệu tổng hợp cho màn Thống kê.
class StatsBundle {
  final UtilizationMetric utilization;
  final ValueMetric value;

  /// Danh sách cost-per-wear theo món. Rỗng khi chưa có dữ liệu
  /// `wearCount` (kèm `wearDataAvailable == false`).
  final List<CostPerWear> costPerWearItems;
  final OutfitStat outfits;
  final List<TimeTrendPoint> trend;

  /// false → ẩn cost-per-wear và xu hướng kèm ghi chú (FR-014).
  final bool wearDataAvailable;

  const StatsBundle({
    this.utilization = const UtilizationMetric(),
    this.value = const ValueMetric(),
    this.costPerWearItems = const [],
    this.outfits = const OutfitStat(),
    this.trend = const [],
    this.wearDataAvailable = false,
  });

  /// true khi có tổng món để hiển thị (ngược lại: trạng thái rỗng).
  bool get hasData => utilization.totalItems > 0;

  /// true khi đủ dữ liệu vẽ biểu đồ (tối thiểu 2 điểm có số liệu).
  bool get hasTrendData =>
      trend.where((p) => p.wearCount > 0).length >= 2;

  factory StatsBundle.fromJson(Map<String, dynamic> json) {
    final data =
        json['data'] is Map<String, dynamic> ? json['data'] : json;
    final cpwList = (data['costPerWearItems'] as List<dynamic>?) ?? [];
    final trendList = (data['trend'] as List<dynamic>?) ?? [];
    return StatsBundle(
      utilization: UtilizationMetric.fromJson(
          (data['utilization'] as Map<String, dynamic>?) ?? {}),
      value: ValueMetric.fromJson(
          (data['value'] as Map<String, dynamic>?) ?? {}),
      costPerWearItems: cpwList
          .map((e) => CostPerWear.fromJson(e as Map<String, dynamic>))
          .toList(),
      outfits: OutfitStat.fromJson(
          (data['outfits'] as Map<String, dynamic>?) ?? {}),
      trend: trendList
          .map((e) => TimeTrendPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      wearDataAvailable: data['wearDataAvailable'] == true,
    );
  }
}
