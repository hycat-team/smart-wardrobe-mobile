import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/outfit_models.dart';
import 'ai_outfit_provider.dart';
import 'outfit_studio_provider.dart';

class OutfitsListState {
  final bool isLoading;
  final List<UserOutfitModel> outfits;
  final String? errorMessage;
  final UserOutfitModel? selectedDetail;
  final bool isLoadingDetail;

  const OutfitsListState({
    this.isLoading = false,
    this.outfits = const [],
    this.errorMessage,
    this.selectedDetail,
    this.isLoadingDetail = false,
  });

  OutfitsListState copyWith({
    bool? isLoading,
    List<UserOutfitModel>? outfits,
    String? errorMessage,
    UserOutfitModel? selectedDetail,
    bool? isLoadingDetail,
    bool clearError = false,
    bool clearDetail = false,
  }) {
    return OutfitsListState(
      isLoading: isLoading ?? this.isLoading,
      outfits: outfits ?? this.outfits,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedDetail: clearDetail ? null : (selectedDetail ?? this.selectedDetail),
      isLoadingDetail: isLoadingDetail ?? this.isLoadingDetail,
    );
  }
}

class OutfitsListNotifier extends StateNotifier<OutfitsListState> {
  final Ref _ref;

  OutfitsListNotifier(this._ref) : super(const OutfitsListState()) {
    fetchOutfits();
  }

  Future<void> fetchOutfits() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repo = _ref.read(outfitRepositoryProvider);
      final list = await repo.getMyOutfits();
      state = state.copyWith(
        isLoading: false,
        outfits: list,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<UserOutfitModel?> fetchOutfitDetail(String id) async {
    state = state.copyWith(isLoadingDetail: true, clearDetail: true);
    try {
      final repo = _ref.read(outfitRepositoryProvider);
      final detail = await repo.getOutfitDetail(id);
      state = state.copyWith(
        isLoadingDetail: false,
        selectedDetail: detail,
      );
      return detail;
    } catch (e) {
      state = state.copyWith(
        isLoadingDetail: false,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return null;
    }
  }

  Future<bool> deleteOutfit(String id) async {
    try {
      final repo = _ref.read(outfitRepositoryProvider);
      await repo.deleteOutfit(id);
      final updatedList = state.outfits.where((o) => o.id != id).toList();
      state = state.copyWith(outfits: updatedList);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// Nạp các món đồ của một outfit đã lưu vào Studio Canvas để chỉnh sửa
  void loadIntoStudio(UserOutfitModel outfit) {
    final canvasItems = <CanvasItem>[];
    int layer = 1;

    for (final item in outfit.items) {
      final fItem = item.fashionItem;
      if (fItem == null) continue;

      canvasItems.add(
        CanvasItem(
          id: '${item.id}_${DateTime.now().millisecondsSinceEpoch}',
          fashionItemId: fItem.id,
          imageUrl: fItem.imageUrl,
          name: fItem.category?.name ?? 'Món đồ',
          positionX: item.positionX,
          positionY: item.positionY,
          scale: item.scale,
          layerOrder: item.layerOrder > 0 ? item.layerOrder : layer++,
        ),
      );
    }

    _ref.read(outfitStudioProvider.notifier).state =
        _ref.read(outfitStudioProvider.notifier).state.copyWith(
              canvasItems: canvasItems,
              clearSelection: true,
              successMessage: 'Đã nạp "${outfit.name}" vào Studio để chỉnh sửa!',
            );
  }
}

final outfitsListProvider = StateNotifierProvider<OutfitsListNotifier, OutfitsListState>((ref) {
  return OutfitsListNotifier(ref);
});
