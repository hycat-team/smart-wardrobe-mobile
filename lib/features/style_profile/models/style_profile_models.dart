class StyleProfileModel {
  final List<String> styles;
  final List<String> excludedStyles;
  final bool enabled;
  final bool personalizationAvailable;
  final bool hasEmbedding;
  final int maxStyles;
  final String? updatedAt;

  const StyleProfileModel({
    this.styles = const [],
    this.excludedStyles = const [],
    this.enabled = true,
    this.personalizationAvailable = false,
    this.hasEmbedding = false,
    this.maxStyles = 4,
    this.updatedAt,
  });

  factory StyleProfileModel.fromJson(Map<String, dynamic> json) {
    List<String> list(dynamic raw) =>
        raw is List ? raw.map((e) => e.toString()).toList(growable: false) : const [];
    return StyleProfileModel(
      styles: list(json['styles']),
      excludedStyles: list(json['excludedStyles']),
      enabled: json['enabled'] is bool ? json['enabled'] as bool : true,
      personalizationAvailable:
          json['personalizationAvailable'] is bool ? json['personalizationAvailable'] as bool : false,
      hasEmbedding: json['hasEmbedding'] is bool ? json['hasEmbedding'] as bool : false,
      maxStyles: json['maxStyles'] is int ? json['maxStyles'] as int : 4,
      updatedAt: json['updatedAt']?.toString(),
    );
  }
}

class StyleValueSuggestionModel {
  final String value;
  final int itemCount;
  final double ratio;

  const StyleValueSuggestionModel({
    required this.value,
    this.itemCount = 0,
    this.ratio = 0,
  });

  factory StyleValueSuggestionModel.fromJson(Map<String, dynamic> json) {
    return StyleValueSuggestionModel(
      value: json['value']?.toString() ?? '',
      itemCount: json['itemCount'] is int ? json['itemCount'] as int : 0,
      ratio: json['ratio'] is num ? (json['ratio'] as num).toDouble() : 0,
    );
  }
}

class StyleSuggestionModel {
  final List<StyleValueSuggestionModel> styles;
  final int sampleSize;

  const StyleSuggestionModel({this.styles = const [], this.sampleSize = 0});

  factory StyleSuggestionModel.fromJson(Map<String, dynamic> json) {
    return StyleSuggestionModel(
      styles: json['styles'] is List
          ? (json['styles'] as List)
              .whereType<Map<String, dynamic>>()
              .map(StyleValueSuggestionModel.fromJson)
              .toList()
          : const [],
      sampleSize: json['sampleSize'] is int ? json['sampleSize'] as int : 0,
    );
  }
}
