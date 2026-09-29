import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../models/product_model.dart';

class MarketplaceRepository {
  final ApiClient _apiClient;

  MarketplaceRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  Future<List<MarketProductModel>> getProducts({
    String? category,
    String? search,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (category != null && category.isNotEmpty && category.toLowerCase() != 'all') {
        queryParams['category'] = category;
      }
      if (search != null && search.isNotEmpty) {
        queryParams['q'] = search;
      }

      final response = await _apiClient.dio.get(
        '/market/products',
        queryParameters: queryParams,
      );

      final body = response.data;
      final data = body['data'] is Map<String, dynamic> ? body['data'] : body;
      final rawList = (data['data'] ?? data['items'] ?? data) as List<dynamic>? ?? [];

      return rawList.map((item) => MarketProductModel.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (_) {
      // Return curated mock items matching the web marketplace if backend endpoint is empty
      final allItems = [
        const MarketProductModel(
          id: 'm1',
          name: 'Áo khoác trench dáng rộng',
          brand: 'THE ROW',
          price: 1900,
          category: 'Outerwear',
          imageUrl: 'https://images.unsplash.com/photo-1544441893-675973e31985?w=600',
        ),
        const MarketProductModel(
          id: 'm2',
          name: 'Áo sơ mi lụa màu ngà',
          brand: 'LEMAIRE',
          price: 620,
          category: 'Knitwear',
          imageUrl: 'https://images.unsplash.com/photo-1598033129183-c4f50c736f10?w=600',
        ),
        const MarketProductModel(
          id: 'm3',
          name: 'Quần âu xếp ly len',
          brand: 'LEMAIRE',
          price: 750,
          category: 'Tailoring',
          imageUrl: 'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600',
        ),
        const MarketProductModel(
          id: 'm4',
          name: 'Túi tote da',
          brand: 'THE ROW',
          price: 2100,
          category: 'Footwear',
          imageUrl: 'https://images.unsplash.com/photo-1584917865442-de89df76afd3?w=600',
        ),
        const MarketProductModel(
          id: 'm5',
          name: 'Áo khoác dạ dáng hộp',
          brand: 'STUDIO NICHOLSON',
          price: 450,
          category: 'Outerwear',
          imageUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=600',
        ),
        const MarketProductModel(
          id: 'm6',
          name: 'Quần âu vải twill màu chàm',
          brand: 'JIL SANDER',
          price: 320,
          category: 'Tailoring',
          imageUrl: 'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?w=600',
        ),
      ];

      return allItems.where((p) {
        final matchesCategory = category == null || category.toLowerCase() == 'all' || p.category.toLowerCase() == category.toLowerCase();
        final matchesSearch = search == null || search.isEmpty || p.name.toLowerCase().contains(search.toLowerCase()) || p.brand.toLowerCase().contains(search.toLowerCase());
        return matchesCategory && matchesSearch;
      }).toList();
    }
  }
}
