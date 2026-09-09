class BodyProfileModel {
  final double heightCm;
  final double weightKg;
  final String bodyShape;
  final double? chestCm;
  final double? waistCm;
  final double? hipCm;
  final bool verifiedByUser;

  const BodyProfileModel({
    this.heightCm = 165.0,
    this.weightKg = 55.0,
    this.bodyShape = 'hourglass',
    this.chestCm,
    this.waistCm,
    this.hipCm,
    this.verifiedByUser = true,
  });

  double get bmi {
    if (heightCm <= 0) return 0.0;
    final hInMeters = heightCm / 100;
    return weightKg / (hInMeters * hInMeters);
  }

  String get bmiCategory {
    final val = bmi;
    if (val <= 0) return 'Chưa xác định';
    if (val < 18.5) return 'Gầy / Mảnh khảnh';
    if (val < 23) return 'Cân đối (Chuẩn châu Á)';
    if (val < 25) return 'Hơi đầy đặn';
    return 'Thừa cân nhẹ';
  }

  String get bodyShapeTitle {
    switch (bodyShape.toLowerCase()) {
      case 'hourglass':
        return 'Đồng hồ cát';
      case 'pear':
        return 'Quả lê (Hông rộng)';
      case 'rectangle':
        return 'Thước kẻ (Hình chữ nhật)';
      case 'inverted_triangle':
        return 'Tam giác ngược (Vai rộng)';
      case 'apple':
        return 'Quả táo (Vòng eo tròn)';
      default:
        return 'Cân đối';
    }
  }

  String get bodyShapeStylingAdvice {
    switch (bodyShape.toLowerCase()) {
      case 'hourglass':
        return 'Tôn đường cong tự nhiên với áo chiết eo, váy ôm bodycon hoặc quần cạp cao thanh lịch.';
      case 'pear':
        return 'Tạo điểm nhấn phần thân trên bằng áo cổ thuyền, tay bồng và phối cùng quần ống đứng sẫm màu.';
      case 'rectangle':
        return 'Tạo ảo giác đường cong với thắt lưng bản vừa, đầm xòe chữ A và áo cổ chữ V sâu.';
      case 'inverted_triangle':
        return 'Làm mềm bờ vai bằng áo cổ chữ V, phối cùng chân váy xòe xếp ly hoặc quần ống rộng suông.';
      case 'apple':
        return 'Ưu tiên trang phục suông nhẹ, đầm empire hoặc áo cổ tim giúp tạo cảm giác thon gọn phần thân trên.';
      default:
        return 'Phù hợp đa dạng phong cách phối đồ.';
    }
  }

  BodyProfileModel copyWith({
    double? heightCm,
    double? weightKg,
    String? bodyShape,
    double? chestCm,
    double? waistCm,
    double? hipCm,
    bool? verifiedByUser,
  }) {
    return BodyProfileModel(
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      bodyShape: bodyShape ?? this.bodyShape,
      chestCm: chestCm ?? this.chestCm,
      waistCm: waistCm ?? this.waistCm,
      hipCm: hipCm ?? this.hipCm,
      verifiedByUser: verifiedByUser ?? this.verifiedByUser,
    );
  }

  Map<String, dynamic> toJson() => {
        'heightCm': heightCm,
        'weightKg': weightKg,
        'bodyShape': bodyShape,
        'measurements': {
          if (chestCm != null) 'chestCm': chestCm,
          if (waistCm != null) 'waistCm': waistCm,
          if (hipCm != null) 'hipCm': hipCm,
        },
        'verifiedByUser': verifiedByUser,
      };

  factory BodyProfileModel.fromJson(Map<String, dynamic> json) {
    final measurements = json['measurements'] is Map ? json['measurements'] as Map<String, dynamic> : null;

    return BodyProfileModel(
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? 165.0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 55.0,
      bodyShape: json['bodyShape']?.toString() ?? 'hourglass',
      chestCm: (measurements?['chestCm'] as num?)?.toDouble(),
      waistCm: (measurements?['waistCm'] as num?)?.toDouble(),
      hipCm: (measurements?['hipCm'] as num?)?.toDouble(),
      verifiedByUser: json['verifiedByUser'] == true,
    );
  }
}
