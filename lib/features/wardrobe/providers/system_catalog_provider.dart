import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/wardrobe_repository.dart';
import '../models/wardrobe_models.dart';
import 'wardrobe_provider.dart';

class SystemCatalogState {
  final bool isLoading;
  final bool isLoadingMore;
  final bool isAdding;
  final List<WardrobeItemModel> items;
  final int page;
  final int total;
  final String? errorMessage;
  final Set<String> selectedIds;
  final String? categorySlug;
  final String query;

  const SystemCatalogState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isAdding = false,
    this.items = const [],
    this.page = 1,
    this.total = 0,
    this.errorMessage,
    this.selectedIds = const {},
    this.categorySlug,
    this.query = '',
  });

  bool get hasMore => items.length < total;
  int get selectedCount => selectedIds.length;

  SystemCatalogState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    bool? isAdding,
    List<WardrobeItemModel>? items,
    int? page,
    int? total,
    String? errorMessage,
    bool clearError = false,
    Set<String>? selectedIds,
    String? categorySlug,
    bool clearCategory = false,
    String? query,
  }) {
    return SystemCatalogState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isAdding: isAdding ?? this.isAdding,
      items: items ?? this.items,
      page: page ?? this.page,
      total: total ?? this.total,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedIds: selectedIds ?? this.selectedIds,
      categorySlug: clearCategory ? null : (categorySlug ?? this.categorySlug),
      query: query ?? this.query,
    );
  }
}

/// Quản lý màn hình tủ đồ hệ thống (US3).
/// Mirror hành vi FE `/wardrobe/explore`: duyệt + lọc + tìm kiếm +
/// tick chọn nhiều + `POST /wardrobe-items/catalog-init`.
class SystemCatalogNotifier extends StateNotifier<SystemCatalogState> {
  static const int _pageSize = 20;
  static const Duration _searchDebounce = Duration(milliseconds: 500);

  final WardrobeRepository _repository;
  final Ref _ref;
  Timer? _searchTimer;

  SystemCatalogNotifier(this._repository, this._ref)
      : super(const SystemCatalogState()) {
    loadCatalog(refresh: true);
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }

  Future<void> loadCatalog({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      if (state.isLoadingMore || !state.hasMore) return;
      state = state.copyWith(isLoadingMore: true, clearError: true);
    }
    try {
      final result = await _repository.getSystemCatalogItems(
        page: refresh ? 1 : state.page + 1,
        limit: _pageSize,
        categorySlug: state.categorySlug,
        query: state.query.isEmpty ? null : state.query,
      );
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        items: refresh ? result.items : [...state.items, ...result.items],
        page: result.page,
        total: result.total,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  void selectCategory(String? slug) {
    _searchTimer?.cancel();
    state = state.copyWith(categorySlug: slug, clearCategory: slug == null);
    loadCatalog(refresh: true);
  }

  /// Tìm kiếm có debounce 500ms (giống FE).
  void setQueryDebounced(String query) {
    _searchTimer?.cancel();
    _searchTimer = Timer(_searchDebounce, () {
      if (!mounted) return;
      if (query.trim() == state.query) return;
      state = state.copyWith(query: query.trim());
      loadCatalog(refresh: true);
    });
  }

  void toggleSelect(String id) {
    // Mẫu đã có trong tủ thì không cho chọn (chống trùng).
    if (isInMyWardrobe(id)) return;
    final next = Set<String>.from(state.selectedIds);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = state.copyWith(selectedIds: next);
  }

  /// true khi mẫu đã tồn tại trong tủ cá nhân (so theo id).
  bool isInMyWardrobe(String catalogId) {
    final myItems = _ref.read(wardrobeProvider).items;
    return myItems.any((it) => it.id == catalogId);
  }

  /// Thêm các mẫu đã chọn vào tủ cá nhân.
  /// Trả về số món đã tạo; thất bại ném Exception với message hiển thị được.
  Future<int> initSelected() async {
    final ids = state.selectedIds.toList();
    if (ids.isEmpty || state.isAdding) return 0;
    state = state.copyWith(isAdding: true, clearError: true);
    try {
      final created = await _repository.initClosetFromCatalog(ids);
      state = state.copyWith(
        isAdding: false,
        selectedIds: const {},
      );
      // Refresh tủ cá nhân để thấy món mới (giống luồng upload xong).
      await _ref.read(wardrobeProvider.notifier).loadItems(refresh: true);
      return created.isEmpty ? ids.length : created.length;
    } catch (e) {
      state = state.copyWith(
        isAdding: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      rethrow;
    }
  }
}

final systemCatalogProvider =
    StateNotifierProvider<SystemCatalogNotifier, SystemCatalogState>((ref) {
  final repo = ref.watch(wardrobeRepositoryProvider);
  return SystemCatalogNotifier(repo, ref);
});
