class MarketProductModel {
  final String id;
  final String name;
  final String brand;
  final double price;
  final String condition;
  final String size;
  final String imageUrl;
  final String category;
  final bool isFavorited;

  const MarketProductModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    this.condition = 'Like New',
    this.size = 'M',
    required this.imageUrl,
    this.category = 'Outerwear',
    this.isFavorited = false,
  });

  MarketProductModel copyWith({bool? isFavorited}) {
    return MarketProductModel(
      id: id,
      name: name,
      brand: brand,
      price: price,
      condition: condition,
      size: size,
      imageUrl: imageUrl,
      category: category,
      isFavorited: isFavorited ?? this.isFavorited,
    );
  }

  factory MarketProductModel.fromJson(Map<String, dynamic> json) {
    return MarketProductModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['title'] ?? '',
      brand: json['brand'] ?? json['brandName'] ?? 'DESIGNER',
      price: json['price'] != null ? (json['price'] as num).toDouble() : 0.0,
      condition: json['condition'] ?? 'Like New',
      size: json['size'] ?? 'M',
      imageUrl: json['imageUrl'] ?? json['img'] ?? '',
      category: json['category'] ?? 'Outerwear',
      isFavorited: json['isFavorited'] ?? false,
    );
  }
}
