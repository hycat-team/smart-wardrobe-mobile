import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/marketplace_repository.dart';
import '../models/product_model.dart';

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  return MarketplaceRepository();
});

class MarketplaceState {
  final List<MarketProductModel> products;
  final bool isLoading;
  final String selectedCategory;
  final String searchQuery;
  final String? errorMessage;

  const MarketplaceState({
    this.products = const [],
    this.isLoading = false,
    this.selectedCategory = 'All',
    this.searchQuery = '',
    this.errorMessage,
  });

  MarketplaceState copyWith({
    List<MarketProductModel>? products,
    bool? isLoading,
    String? selectedCategory,
    String? searchQuery,
    String? errorMessage,
  }) {
    return MarketplaceState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
    );
  }
}

class MarketplaceNotifier extends StateNotifier<MarketplaceState> {
  final MarketplaceRepository _repository;

  MarketplaceNotifier(this._repository) : super(const MarketplaceState()) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final items = await _repository.getProducts(
        category: state.selectedCategory,
        search: state.searchQuery,
      );
      state = state.copyWith(products: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setCategory(String category) {
    if (state.selectedCategory == category) return;
    state = state.copyWith(selectedCategory: category);
    loadProducts();
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    loadProducts();
  }

  void toggleFavorite(String productId) {
    final updated = state.products.map((p) {
      if (p.id == productId) {
        return p.copyWith(isFavorited: !p.isFavorited);
      }
      return p;
    }).toList();
    state = state.copyWith(products: updated);
  }
}

final marketplaceProvider = StateNotifierProvider<MarketplaceNotifier, MarketplaceState>((ref) {
  final repo = ref.watch(marketplaceRepositoryProvider);
  return MarketplaceNotifier(repo);
});
